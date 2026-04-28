from datetime import datetime, timedelta, timezone
import re

from fastapi import APIRouter, HTTPException
from models.job_model import JobCreate, JobApplication, ApplicationStatusUpdate
from services.firebase_service import (
    add_document, get_document, get_collection,
    update_document, delete_document, save_document
)
from services.ai_service import match_jobs_to_user
from services.gemini_service import gemini_rank_jobs_for_user, gemini_chat_reply
from services.job_visibility import filter_visible_jobs, job_is_visible
from typing import List, Optional

router = APIRouter(prefix="/jobs", tags=["Jobs"])


def _clean_application_text(text: str) -> str:
    """Remove template placeholders and boilerplate from AI output."""
    if not text:
        return ""

    cleaned_lines = []
    for line in text.splitlines():
        s = line.strip()
        if not s:
            continue
        lower = s.lower()
        # Remove placeholder/template lines like [Your Address], [Date], etc.
        if "[" in s and "]" in s:
            continue
        # Skip address/date headers often generated in generic templates.
        if lower in {"date", "address"}:
            continue
        cleaned_lines.append(s)

    cleaned = " ".join(cleaned_lines)
    cleaned = re.sub(r"\s+", " ", cleaned).strip()
    return cleaned

@router.post("/post")
async def post_job(job: JobCreate):
    """Recruiter posts a new job."""
    try:
        data = job.model_dump(mode="json")
        data["is_active"] = True
        now = datetime.now(timezone.utc)
        data["posted_at"] = now.isoformat().replace("+00:00", "Z")
        data["expires_at"] = (
            now + timedelta(days=job.listing_days)
        ).isoformat().replace("+00:00", "Z")
        job_id = await add_document("jobs", data)
        return {"message": "Job posted successfully", "job_id": job_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/list")
async def list_jobs(state: Optional[str] = None, district: Optional[str] = None):
    """List all active, non-expired jobs, optionally filtered by location."""
    filters = [{"field": "is_active", "op": "==", "value": True}]
    jobs = await get_collection("jobs", filters)
    jobs = filter_visible_jobs(jobs)

    if state:
        jobs = [j for j in jobs if j.get("state", "").lower() == state.lower()]
    if district:
        jobs = [j for j in jobs if j.get("district", "").lower() == district.lower()]

    return {"jobs": jobs, "count": len(jobs)}

@router.get("/match/{uid}")
async def match_jobs(uid: str):
    """Return AI-ranked job matches for a specific user."""
    user = await get_document("users", uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    skills = user.get("skills", [])
    interests = user.get("interests", [])
    state = user.get("state", "")
    district = user.get("district", "")

    filters = [{"field": "is_active", "op": "==", "value": True}]
    all_jobs = await get_collection("jobs", filters)
    all_jobs = filter_visible_jobs(all_jobs)

    if state:
        local_jobs = [j for j in all_jobs if j.get("state", "").lower() == state.lower()]
        if not local_jobs:
            local_jobs = all_jobs
    else:
        local_jobs = all_jobs

    gemini_ranked = await gemini_rank_jobs_for_user(skills, interests, local_jobs)
    if gemini_ranked is not None:
        if len(gemini_ranked) == 0 and local_jobs:
            ranked = match_jobs_to_user(skills + interests, local_jobs)
        else:
            ranked = gemini_ranked
    else:
        ranked = match_jobs_to_user(skills + interests, local_jobs)
    return {"matched_jobs": ranked[:20]}


@router.get("/mine/{recruiter_uid}")
async def list_my_posted_jobs(recruiter_uid: str):
    """Jobs posted by this recruiter (non-expired)."""
    jobs = await get_collection(
        "jobs",
        [{"field": "recruiter_uid", "op": "==", "value": recruiter_uid}],
    )
    jobs = filter_visible_jobs(jobs)
    return {"jobs": jobs, "count": len(jobs)}

@router.post("/apply")
async def apply_for_job(application: JobApplication):
    """Job finder applies to a job."""
    try:
        data = application.model_dump()
        # Prevent duplicate applications for same user/job.
        existing = await get_collection(
            "applications",
            [
                {"field": "job_id", "op": "==", "value": application.job_id},
                {"field": "applicant_uid", "op": "==", "value": application.applicant_uid},
            ],
        )
        if existing:
            raise HTTPException(status_code=409, detail="Already applied to this job")

        app_id = await add_document("applications", data)
        # Move to saved jobs automatically after successful apply.
        user = await get_document("users", application.applicant_uid)
        if user:
            saved = user.get("saved_jobs", []) or []
            if application.job_id not in saved:
                saved.append(application.job_id)
                await update_document("users", application.applicant_uid, {"saved_jobs": saved})
        return {"message": "Application submitted", "application_id": app_id}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/ai-application/{job_id}/{uid}")
async def generate_ai_application(job_id: str, uid: str):
    """Generate a suitable job application draft using Gemini."""
    user = await get_document("users", uid)
    job = await get_document("jobs", job_id)
    if not user or not job:
        raise HTTPException(status_code=404, detail="User or job not found")

    candidate_name = user.get("name", "").strip() or "the candidate"
    job_title = job.get("title", "").strip() or "this role"
    company = job.get("company", "").strip() or "your organization"
    required_skills = job.get("skills_required", []) or []
    user_skills = user.get("skills", []) or []

    prompt = (
        "Write one ready-to-send job application for a part-time/entry-level role.\n"
        "Output only the final application text as one short paragraph (100-140 words).\n"
        "Do NOT include placeholders or bracketed fields like [Your Address], [Date], [Employer Name].\n"
        "Do NOT include postal address blocks, subject lines, or headings.\n"
        "Use first person and mention only real details provided below.\n\n"
        f"Candidate name: {candidate_name}\n"
        f"Job title: {job_title}\n"
        f"Company/shop: {company}\n"
        f"Job description: {job.get('description', '')}\n"
        f"Skills required: {required_skills}\n"
        f"Candidate skills: {user_skills}\n"
        f"Candidate interests: {user.get('interests', [])}\n"
    )
    reply = await gemini_chat_reply(
        message=prompt,
        user_profile=user,
        language=user.get("preferred_language", "English"),
    )
    reply = _clean_application_text(reply or "")

    if not reply:
        matched_skills = [s for s in user_skills if s in required_skills][:3]
        skills_text = ", ".join(matched_skills or user_skills[:3]) or "customer service and teamwork"
        reply = (
            f"Dear Hiring Team, my name is {candidate_name}, and I am applying for the {job_title} position at {company}. "
            f"I bring strengths in {skills_text} and a strong willingness to learn quickly on the job. "
            "I am dependable, comfortable supporting daily store operations, and focused on giving customers a positive experience. "
            "I would value the opportunity to contribute to your team and am available for flexible part-time hours. "
            "Thank you for your consideration."
        )
    return {"application_text": reply}

@router.get("/applications/{recruiter_uid}")
async def get_applications_for_recruiter(recruiter_uid: str):
    """Recruiter views all applications for their jobs."""
    recruiter_jobs = await get_collection("jobs", [{"field": "recruiter_uid", "op": "==", "value": recruiter_uid}])
    job_ids = [j["id"] for j in recruiter_jobs if "id" in j]
    
    all_apps = []
    for jid in job_ids:
        apps = await get_collection("applications", [{"field": "job_id", "op": "==", "value": jid}])
        all_apps.extend(apps)
    
    return {"applications": all_apps}

@router.patch("/applications/{app_id}/status")
async def update_application_status(app_id: str, update: ApplicationStatusUpdate):
    """Recruiter accepts or rejects an application."""
    await update_document("applications", app_id, {"status": update.status})
    return {"message": f"Application {update.status}"}

@router.get("/my-applications/{uid}")
async def get_my_applications(uid: str):
    """Job finder views their own applications."""
    apps = await get_collection("applications", [{"field": "applicant_uid", "op": "==", "value": uid}])
    return {"applications": apps}

@router.get("/saved/{uid}")
async def get_saved_jobs(uid: str):
    """Get saved jobs for a user."""
    user = await get_document("users", uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    saved_ids = user.get("saved_jobs", [])
    saved = []
    for jid in saved_ids:
        job = await get_document("jobs", jid)
        if job:
            job["id"] = jid
            if job_is_visible(job):
                saved.append(job)
    return {"saved_jobs": saved}

@router.post("/save/{uid}/{job_id}")
async def save_job(uid: str, job_id: str):
    """Save a job to user's saved list."""
    user = await get_document("users", uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    saved = user.get("saved_jobs", [])
    if job_id not in saved:
        saved.append(job_id)
        await update_document("users", uid, {"saved_jobs": saved})
    return {"message": "Job saved"}
