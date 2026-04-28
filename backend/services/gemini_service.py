"""
Gemini-powered job matching, course selection, and weekly plans.
Falls back when GEMINI_API_KEY is unset or the API errors.
"""

from __future__ import annotations

import asyncio
import json
import re
import uuid
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import urlparse

import httpx

from config import settings


def _parse_json_object(text: str) -> Optional[dict]:
    if not text:
        return None
    t = text.strip()
    if "```" in t:
        t = re.sub(r"^```(?:json)?\s*", "", t)
        t = re.sub(r"\s*```$", "", t)
    m = re.search(r"\{[\s\S]*\}", t)
    if m:
        t = m.group(0)
    try:
        return json.loads(t)
    except json.JSONDecodeError:
        return None


def _generate(prompt: str) -> str:
    if not settings.openrouter_api_key:
        return ""

    headers = {
        "Authorization": f"Bearer {settings.openrouter_api_key}",
        "Content-Type": "application/json",
    }
    if settings.openrouter_site_url:
        headers["HTTP-Referer"] = settings.openrouter_site_url
    if settings.openrouter_app_name:
        headers["X-Title"] = settings.openrouter_app_name

    payload = {
        "model": settings.openrouter_model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.3,
    }

    with httpx.Client(timeout=45.0) as client:
        resp = client.post(
            "https://openrouter.ai/api/v1/chat/completions",
            headers=headers,
            json=payload,
        )
        resp.raise_for_status()
        data = resp.json()
        choices = data.get("choices") or []
        if not choices:
            return ""
        message = choices[0].get("message") or {}
        return (message.get("content") or "").strip()


async def gemini_rank_jobs_for_user(
    user_skills: List[str],
    user_interests: List[str],
    jobs: List[Dict[str, Any]],
) -> Optional[List[Dict[str, Any]]]:
    """
    Reorder jobs by semantic skill/interest fit. Returns None = use embedding fallback.
    Empty list = Gemini found no suitable jobs.
    """
    if not settings.openrouter_api_key or not jobs:
        return None

    def _run() -> Optional[List[Dict[str, Any]]]:
        try:
            summaries = [
                {
                    "id": j.get("id", ""),
                    "title": j.get("title", ""),
                    "skills_required": j.get("skills_required", []),
                }
                for j in jobs
                if j.get("id")
            ]
            if not summaries:
                return None
            prompt = f"""Match job seekers to jobs using semantic skill fit.
Examples: job needs "shop worker" and user skill "worker" => include. Job needs "Python" and user only "retail sales" with no tech interest => exclude.

User skills: {json.dumps(user_skills)}
User interests: {json.dumps(user_interests)}

Jobs: {json.dumps(summaries)}

Return ONLY JSON: {{"ranked_ids": ["id1", "id2", ...]}}
- Best matches first. Include every job that plausibly fits skills OR interests.
- If none fit, return {{"ranked_ids": []}}."""
            text = _generate(prompt)
            data = _parse_json_object(text)
            if not data or "ranked_ids" not in data:
                return None
            order = data["ranked_ids"]
            id_to_job = {str(j["id"]): j for j in jobs if j.get("id")}
            ranked: List[Dict[str, Any]] = []
            seen = set()
            for jid in order:
                sid = str(jid)
                if sid in id_to_job and sid not in seen:
                    ranked.append(id_to_job[sid])
                    seen.add(sid)
            return ranked
        except Exception as e:
            print(f"OpenRouter job ranking error: {e}")
            return None

    return await asyncio.to_thread(_run)


# Host substrings for URLs we accept from the model (reduces fake links).
_FREE_COURSE_URL_ALLOWLIST = (
    "youtube.com",
    "youtu.be",
    "khanacademy.org",
    "ocw.mit.edu",
    "archive.nptel.ac.in",
    "nptel.ac.in",
    "onlinecourses.nptel.ac.in",
    "cs50.harvard.edu",
    "pll.harvard.edu",
    "learndigital.withgoogle.com",
    "freecodecamp.org",
    "developer.mozilla.org",
    "swayam.gov.in",
    "skills.google",
    "classcentral.com",
    "scrimba.com",
    "theodinproject.com",
)


def is_trusted_free_learning_url(url: str) -> bool:
    """True if URL looks like https and host is on our free-learning allowlist."""
    u = (url or "").strip().lower()
    if not u.startswith("https://"):
        return False
    if len(u) > 2048:
        return False
    try:
        host = urlparse(u).netloc.lower()
    except Exception:
        return False
    if not host:
        return False
    return any(s in host or s in u for s in _FREE_COURSE_URL_ALLOWLIST)


def _normalize_ai_course_row(raw: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    title = (raw.get("title") or "").strip()
    url = (raw.get("url") or "").strip()
    if not title or not is_trusted_free_learning_url(url):
        return None
    platform = (raw.get("platform") or "Web").strip() or "Web"
    language = (raw.get("language") or "English").strip() or "English"
    tags = raw.get("tags") or []
    if not isinstance(tags, list):
        tags = []
    tags = [str(t).strip() for t in tags if str(t).strip()][:12]
    duration = raw.get("duration")
    duration = str(duration).strip() if duration is not None else None
    desc = (raw.get("description") or "").strip() or None
    return {
        "id": f"ai_{uuid.uuid4().hex[:12]}",
        "title": title[:200],
        "platform": platform[:80],
        "url": url,
        "language": language[:40],
        "tags": tags,
        "is_free": True,
        "duration": duration[:80] if duration else None,
        "description": desc[:400] if desc else None,
    }


async def openrouter_recommend_free_courses_from_profile(
    skills: List[str],
    interests: List[str],
    preferred_language: str = "English",
) -> Optional[Tuple[List[Dict[str, Any]], str]]:
    """
    Ask the LLM for free learning resources tailored to the user.
    Returns None if OpenRouter is not configured or the call fails.
    """
    if not settings.openrouter_api_key:
        return None

    def _run() -> Optional[Tuple[List[Dict[str, Any]], str]]:
        try:
            prompt = f"""You recommend FREE learning resources for job seekers in India (NaviUdan app).

User skills: {json.dumps(skills)}
User interests: {json.dumps(interests)}
Preferred language for explanations (titles may stay English): {preferred_language}

Return ONLY valid JSON (no markdown) with this shape:
{{
  "courses": [
    {{
      "title": "string",
      "platform": "string (e.g. YouTube, Khan Academy, MIT OCW, NPTEL, Google Digital Garage, freeCodeCamp)",
      "url": "https://...",
      "language": "English or Hindi etc.",
      "tags": ["short", "keywords"],
      "duration": "optional rough length",
      "description": "one sentence why it fits this user"
    }}
  ],
  "message": "short friendly note to the learner"
}}

Rules:
- Suggest 5 to 8 items. Every item must be FREE to start (no paid-only products).
- Each "url" MUST be a real https link you are confident exists, from reputable free providers only, for example:
  YouTube (official channels or well-known playlists), Khan Academy, MIT OCW, NPTEL / NPTEL archive,
  Harvard CS50 site, Google Digital Garage / Grow with Google, freeCodeCamp (site or YouTube), MDN Web Docs learning,
  Swayam, The Odin Project, Scrimba free tiers, Class Central listings that point to free content.
- Do NOT invent URLs. If unsure, omit that course rather than guessing.
- Match resources to the user's skills OR interests (including non-technical paths like retail, communication, sales).
- Prefer India-relevant options when possible (e.g. NPTEL, Swayam) alongside global staples."""

            text = _generate(prompt)
            data = _parse_json_object(text)
            if not data:
                return None
            raw_list = data.get("courses")
            if not isinstance(raw_list, list):
                return None
            msg = (data.get("message") or "").strip()
            out: List[Dict[str, Any]] = []
            for raw in raw_list[:10]:
                if isinstance(raw, dict):
                    row = _normalize_ai_course_row(raw)
                    if row:
                        out.append(row)
                if len(out) >= 8:
                    break
            if not out:
                return None
            return (out, msg or "Here are free courses picked for your profile.")
        except Exception as e:
            print(f"OpenRouter free-course recommend error: {e}")
            return None

    return await asyncio.to_thread(_run)


async def gemini_recommend_courses(
    skills: List[str],
    interests: List[str],
    catalogue: List[Dict[str, Any]],
) -> Optional[Tuple[List[Dict[str, Any]], str]]:
    """
    Returns (courses, message). None = caller should use tag-based fallback.
    Empty courses + message when Gemini says nothing fits.
    """
    if not settings.openrouter_api_key or not catalogue:
        return None

    def _run() -> Optional[Tuple[List[Dict[str, Any]], str]]:
        try:
            slim = [
                {
                    "id": c["id"],
                    "title": c["title"],
                    "tags": c.get("tags", []),
                    "platform": c.get("platform", ""),
                }
                for c in catalogue
                if c.get("id")
            ]
            prompt = f"""Pick ONLY courses from the catalogue that clearly relate to the user's skills OR interests (semantic match). Do not pad with unrelated courses.
If skills are non-technical but interests are technical (e.g. IT), you may suggest courses matching those interests.
If nothing in the catalogue fits, return an empty selected_ids list.

User skills: {json.dumps(skills)}
User interests: {json.dumps(interests)}

Catalogue: {json.dumps(slim)}

Return ONLY JSON: {{"selected_ids": ["id1", ...], "message": "short note"}}
- selected_ids: catalogue ids only, max 8, strongest matches first.
- If none fit: {{"selected_ids": [], "message": "No courses available for your profile"}}."""
            text = _generate(prompt)
            data = _parse_json_object(text)
            if not data:
                return None
            ids = data.get("selected_ids") or []
            msg = (data.get("message") or "").strip()
            id_set = {str(c["id"]): c for c in catalogue}
            picked = [id_set[i] for i in map(str, ids) if i in id_set]
            if not picked and not msg:
                msg = "No courses available"
            return (picked, msg)
        except Exception as e:
            print(f"OpenRouter courses error: {e}")
            return None

    return await asyncio.to_thread(_run)


async def gemini_weekly_plan(
    skills: List[str],
    interests: List[str],
) -> Optional[Tuple[List[Dict[str, Any]], str]]:
    """
    Returns (plan_days, message). None = caller uses rule-based plan.
    """
    if not settings.openrouter_api_key:
        return None

    def _run() -> Optional[Tuple[List[Dict[str, Any]], str]]:
        try:
            prompt = f"""Build a 7-day learning plan (Monday–Sunday) for this user.
If skills are purely manual/non-academic and interests are not technical, a structured course plan may not apply — return empty plan with an honest message.

User skills: {json.dumps(skills)}
User interests: {json.dumps(interests)}

Return ONLY JSON: {{
  "days": [
    {{"day": "Monday", "topic": "...", "goal": "...", "resource": "..."}}
  ],
  "message": ""
}}
- Either 7 entries in "days" OR empty "days" with message like "No weekly plan available" explaining why."""
            text = _generate(prompt)
            data = _parse_json_object(text)
            if not data:
                return None
            days = data.get("days") or []
            msg = (data.get("message") or "").strip()
            if not days:
                if not msg:
                    msg = "No weekly plan available"
                return ([], msg)
            out = []
            for d in days[:7]:
                if isinstance(d, dict):
                    out.append(
                        {
                            "day": d.get("day", ""),
                            "topic": d.get("topic", ""),
                            "goal": d.get("goal", ""),
                            "resource": d.get("resource", ""),
                        }
                    )
            return (out, msg)
        except Exception as e:
            print(f"OpenRouter weekly plan error: {e}")
            return None

    return await asyncio.to_thread(_run)


async def gemini_weekly_plan_for_course(
    course: Dict[str, Any],
    skills: List[str],
    interests: List[str],
) -> Optional[Tuple[List[Dict[str, Any]], str]]:
    """
    7-day plan scoped to one selected course. Each day's resource must use the course URL.
    """
    if not settings.openrouter_api_key:
        return None

    title = course.get("title", "")
    url = course.get("url", "")
    platform = course.get("platform", "")
    tags = course.get("tags", []) or []
    description = (course.get("description") or "").strip()
    duration = (course.get("duration") or "").strip()

    def _run() -> Optional[Tuple[List[Dict[str, Any]], str]]:
        try:
            prompt = f"""Build a 7-day learning plan (Monday–Sunday) for ONE specific free course.
The learner will follow this single course link throughout the week — break it into logical daily chunks.

Course title: {title}
Platform: {platform}
Course URL (use this EXACT URL as the "resource" field for EVERY day): {url}
Topics/tags: {json.dumps(tags)}
Duration note: {duration}
Description: {description or "not provided"}

Learner skills: {json.dumps(skills)}
Learner interests: {json.dumps(interests)}

Return ONLY JSON: {{
  "days": [
    {{"day": "Monday", "topic": "short topic for that day", "goal": "specific measurable goal", "resource": "{url}"}}
  ],
  "message": "optional short encouragement"
}}
Rules:
- Exactly 7 entries Monday through Sunday.
- Each "resource" must be exactly: {url}
- Goals should reference concrete actions (watch X min, complete exercise, quiz, chapter) appropriate to the platform.
- Do not invent other URLs."""
            text = _generate(prompt)
            data = _parse_json_object(text)
            if not data:
                return None
            days = data.get("days") or []
            msg = (data.get("message") or "").strip()
            if len(days) < 7:
                return None
            out = []
            for d in days[:7]:
                if isinstance(d, dict):
                    out.append(
                        {
                            "day": d.get("day", ""),
                            "topic": d.get("topic", ""),
                            "goal": d.get("goal", ""),
                            "resource": url or (d.get("resource") or ""),
                        }
                    )
            return (out, msg)
        except Exception as e:
            print(f"OpenRouter weekly plan (course) error: {e}")
            return None

    return await asyncio.to_thread(_run)


async def gemini_chat_reply(
    message: str,
    user_profile: Dict[str, Any] | None,
    language: str,
) -> Optional[str]:
    """Conversational NaviBot reply. None = use rule-based fallback."""
    if not settings.openrouter_api_key:
        return None

    def _run() -> Optional[str]:
        try:
            name = "there"
            skills: List[str] = []
            interests: List[str] = []
            role = ""
            state = ""
            if user_profile:
                name = user_profile.get("name") or name
                skills = user_profile.get("skills") or []
                interests = user_profile.get("interests") or []
                role = user_profile.get("role") or ""
                state = user_profile.get("state") or ""
            prompt = f"""You are NaviBot, the in-app career assistant for NaviUdan (India — jobs, skills, learning).

Reply in the user's preferred language when it fits naturally: {language}
Keep answers concise (under 220 words), warm and practical. No markdown headings.

User name: {name}
Role: {role or "not set"}
State/region: {state or "not set"}
Skills: {json.dumps(skills)}
Interests / fields of interest: {json.dumps(interests)}

User message:
{message}

Give helpful, specific guidance. If they ask about jobs or courses, relate answers to their listed skills and interests."""
            return _generate(prompt) or None
        except Exception as e:
            print(f"OpenRouter chat error: {e}")
            return None

    return await asyncio.to_thread(_run)
