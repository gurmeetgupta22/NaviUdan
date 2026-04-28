from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from models.ai_model import AIAnalysisRequest, AIAnalysisResponse, ChatRequest, ChatResponse
from services.ai_service import generate_career_analysis, answer_career_question
from services.gemini_service import gemini_chat_reply, gemini_weekly_plan, gemini_weekly_plan_for_course
from services.firebase_service import get_document

router = APIRouter(prefix="/ai", tags=["AI Bot"])

@router.post("/analyze", response_model=AIAnalysisResponse)
async def analyze_career(request: AIAnalysisRequest):
    """
    Full AI career analysis:
    - Skill gap detection
    - Career direction
    - Learning roadmap
    - Course recommendations
    - Weekly plan
    """
    try:
        result = generate_career_analysis(
            skills=request.skills,
            interests=request.interests,
            education=request.education or "",
            work_experience=request.work_experience or "",
            state=request.state or "default",
            language=request.language,
        )
        return AIAnalysisResponse(**result)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/chat", response_model=ChatResponse)
async def chat_with_bot(request: ChatRequest):
    """AI career chatbot — Gemini when configured, else rule-based."""
    try:
        user = await get_document("users", request.uid)
        reply = await gemini_chat_reply(
            request.message,
            user,
            request.language,
        )
        if not reply:
            skills = user.get("skills", []) if user else []
            reply = answer_career_question(
                request.message, skills, request.language
            )
        return ChatResponse(reply=reply)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/trending/{state}")
async def trending_fields(state: str):
    """Get trending job fields for a given state."""
    from services.ai_service import get_trending_fields
    fields = get_trending_fields(state)
    return {"state": state, "trending_fields": fields}

@router.get("/weekly-plan/{uid}")
async def get_weekly_plan(
    uid: str,
    course_id: Optional[str] = Query(
        default=None,
        description="Optional catalogue id — builds a 7-day plan around that free course.",
    ),
    course_title: Optional[str] = Query(
        default=None,
        description="With course_url, builds a plan for an AI-recommended course (not in static catalogue).",
    ),
    course_url: Optional[str] = Query(
        default=None,
        description="HTTPS link to the course (must be sent with course_title).",
    ),
):
    """Generate a weekly learning plan for a user, optionally tied to one selected course."""
    user = await get_document("users", uid)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    from services.gemini_service import is_trusted_free_learning_url

    from routers.courses import get_course_by_id
    from services.ai_service import generate_weekly_plan, generate_weekly_plan_for_course

    skills = user.get("skills", []) or []
    interests = user.get("interests", []) or []

    title_param = (course_title or "").strip()
    url_param = (course_url or "").strip()

    if title_param and url_param:
        if not is_trusted_free_learning_url(url_param):
            raise HTTPException(status_code=400, detail="course_url must be a trusted https learning link.")
        course = {
            "id": course_id or "custom",
            "title": title_param[:300],
            "url": url_param[:2048],
            "platform": "Web",
            "tags": list(skills[:4] + interests[:4]),
            "description": "",
            "duration": "",
        }
        gemini = await gemini_weekly_plan_for_course(course, skills, interests)
        if gemini is not None:
            plan, msg = gemini
            if plan:
                header = f"Weekly plan for: {title_param}"
                msg = f"{header}. {msg}".strip() if msg else header
                return {
                    "uid": uid,
                    "course_id": str(course.get("id", "")),
                    "course_title": title_param,
                    "weekly_plan": plan,
                    "message": msg,
                }

        plan = generate_weekly_plan_for_course(title_param, url_param, course["tags"])
        return {
            "uid": uid,
            "course_id": str(course.get("id", "")),
            "course_title": title_param,
            "weekly_plan": plan,
            "message": f"Weekly plan for: {title_param}",
        }

    if course_id:
        course = get_course_by_id(course_id)
        if not course:
            raise HTTPException(status_code=404, detail="Course not found")

        title = course.get("title", "Course")
        url = course.get("url", "")
        tags = list(course.get("tags", []) or [])

        gemini = await gemini_weekly_plan_for_course(course, skills, interests)
        if gemini is not None:
            plan, msg = gemini
            if plan:
                header = f"Weekly plan for: {title}"
                msg = f"{header}. {msg}".strip() if msg else header
                return {
                    "uid": uid,
                    "course_id": str(course.get("id", "")),
                    "course_title": title,
                    "weekly_plan": plan,
                    "message": msg,
                }

        plan = generate_weekly_plan_for_course(title, url, tags)
        return {
            "uid": uid,
            "course_id": str(course.get("id", "")),
            "course_title": title,
            "weekly_plan": plan,
            "message": f"Weekly plan for: {title}",
        }

    gemini = await gemini_weekly_plan(skills, interests)
    if gemini is not None:
        plan, msg = gemini
        return {"uid": uid, "weekly_plan": plan, "message": msg, "course_id": None, "course_title": None}

    plan = generate_weekly_plan(skills=skills, interests=interests)
    return {"uid": uid, "weekly_plan": plan, "message": "", "course_id": None, "course_title": None}
