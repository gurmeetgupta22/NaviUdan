"""
AI Service – uses sentence-transformers for embedding-based
job/course matching and rule-based NLP for career guidance.
Falls back gracefully if the model hasn't been downloaded yet.
"""

from typing import List, Dict, Any
import json

# ─── Static knowledge base ──────────────────────────────────────────────────

SKILL_CAREER_MAP: Dict[str, Dict[str, Any]] = {
    "python": {
        "career": "Software Developer / Data Scientist",
        "related_skills": ["machine learning", "django", "flask", "sql", "docker"],
        "courses": [
            {"title": "Python for Everybody", "platform": "Coursera", "url": "https://www.coursera.org/specializations/python", "is_free": False},
            {"title": "Python Crash Course", "platform": "YouTube", "url": "https://youtube.com/watch?v=rfscVS0vtbw", "is_free": True},
        ],
    },
    "machine learning": {
        "career": "ML Engineer / Data Scientist",
        "related_skills": ["python", "tensorflow", "pytorch", "statistics", "sql"],
        "courses": [
            {"title": "ML by Andrew Ng", "platform": "Coursera", "url": "https://www.coursera.org/learn/machine-learning", "is_free": False},
            {"title": "Machine Learning Crash Course", "platform": "YouTube", "url": "https://youtube.com/watch?v=KNAWp2S3w94", "is_free": True},
        ],
    },
    "web development": {
        "career": "Frontend / Full-Stack Developer",
        "related_skills": ["html", "css", "javascript", "react", "nodejs"],
        "courses": [
            {"title": "The Web Developer Bootcamp", "platform": "Udemy", "url": "https://www.udemy.com/course/the-web-developer-bootcamp/", "is_free": False},
            {"title": "Full Web Dev Course", "platform": "YouTube", "url": "https://youtube.com/watch?v=mU6anWqZJcc", "is_free": True},
        ],
    },
    "data analysis": {
        "career": "Data Analyst",
        "related_skills": ["python", "excel", "sql", "tableau", "power bi"],
        "courses": [
            {"title": "Google Data Analytics", "platform": "Coursera", "url": "https://www.coursera.org/professional-certificates/google-data-analytics", "is_free": False},
            {"title": "Data Analysis with Python", "platform": "YouTube", "url": "https://youtube.com/watch?v=r-uOLxNrNk8", "is_free": True},
        ],
    },
    "sales": {
        "career": "Sales Executive / Business Development",
        "related_skills": ["communication", "negotiation", "crm", "marketing"],
        "courses": [
            {"title": "Sales Training", "platform": "YouTube", "url": "https://youtube.com/watch?v=PHSdMGYZm_4", "is_free": True},
        ],
    },
    "teaching": {
        "career": "Teacher / Educator / Trainer",
        "related_skills": ["communication", "content creation", "classroom management"],
        "courses": [
            {"title": "Teaching & Instruction", "platform": "Coursera", "url": "https://www.coursera.org/learn/teach", "is_free": False},
        ],
    },
    "healthcare": {
        "career": "Healthcare / Nursing / Medical Assistant",
        "related_skills": ["first aid", "patient care", "medical terminologies"],
        "courses": [
            {"title": "Healthcare Basics", "platform": "YouTube", "url": "https://youtube.com/watch?v=HU3HjNQDDd8", "is_free": True},
        ],
    },
}

TRENDING_FIELDS_BY_STATE: Dict[str, List[str]] = {
    "Maharashtra":    ["IT", "Finance", "Manufacturing", "Healthcare"],
    "Karnataka":      ["IT", "AI", "Startups", "Biotechnology"],
    "Tamil Nadu":     ["Manufacturing", "IT", "Automobile", "Healthcare"],
    "Delhi":          ["Finance", "Retail", "IT", "Government"],
    "Rajasthan":      ["Tourism", "Agriculture", "Teaching", "Government"],
    "Uttar Pradesh":  ["Agriculture", "Teaching", "Government", "Retail"],
    "default":        ["IT", "Sales", "Healthcare", "Teaching", "Agriculture"],
}


# ─── Embedding model (lazy-loaded) ──────────────────────────────────────────

_model = None

def _get_model():
    global _model
    if _model is None:
        try:
            from sentence_transformers import SentenceTransformer
            _model = SentenceTransformer("all-MiniLM-L6-v2")
        except Exception as e:
            print(f"⚠️  Could not load sentence-transformers model: {e}")
            _model = None
    return _model


def _cosine_similarity(v1, v2) -> float:
    import numpy as np
    v1, v2 = np.array(v1), np.array(v2)
    denom = (np.linalg.norm(v1) * np.linalg.norm(v2))
    return float(np.dot(v1, v2) / denom) if denom else 0.0


# ─── Core AI functions ───────────────────────────────────────────────────────

def get_trending_fields(state: str) -> List[str]:
    return TRENDING_FIELDS_BY_STATE.get(state, TRENDING_FIELDS_BY_STATE["default"])


def detect_skill_gaps(user_skills: List[str], interests: List[str]) -> Dict[str, Any]:
    user_skills_lower = [s.lower() for s in user_skills]
    gaps: List[str] = []
    suggested: List[str] = []
    career = "General Professional"
    courses = []

    for interest in interests:
        key = interest.lower()
        if key in SKILL_CAREER_MAP:
            entry = SKILL_CAREER_MAP[key]
            career = entry["career"]
            for skill in entry["related_skills"]:
                if skill not in user_skills_lower and skill not in gaps:
                    gaps.append(skill)
                    if skill not in suggested:
                        suggested.append(skill)
            courses.extend(entry["courses"])

    # Also check user skills against the map
    for skill in user_skills_lower:
        if skill in SKILL_CAREER_MAP:
            entry = SKILL_CAREER_MAP[skill]
            if career == "General Professional":
                career = entry["career"]
            for s in entry["related_skills"]:
                if s not in user_skills_lower and s not in suggested:
                    suggested.append(s)
            courses.extend(entry["courses"])

    return {
        "skill_gaps": gaps[:6],
        "suggested_skills": suggested[:6],
        "career_direction": career,
        "courses": courses[:5],
    }


def generate_weekly_plan(skills: List[str], interests: List[str]) -> List[Dict]:
    topics = list(set(skills + interests))[:7]
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    plan = []
    for i, day in enumerate(days):
        topic = topics[i % len(topics)] if topics else "General Learning"
        plan.append({
            "day": day,
            "topic": topic.title(),
            "goal": f"Study and practice {topic.title()} for 1–2 hours",
            "resource": f"Search '{topic} tutorial' on YouTube or Coursera",
        })
    return plan


def generate_weekly_plan_for_course(
    course_title: str,
    course_url: str,
    tags: List[str],
) -> List[Dict]:
    """Rule-based 7-day outline for a single course; every day links to the same course URL."""
    days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    focus = tags[:4] if tags else ["the course"]
    steps = [
        ("Orientation", f"Skim the course outline and set up any accounts or software needed for {course_title}."),
        ("Foundations — part 1", f"Start early modules; focus on {focus[0] if focus else 'core concepts'} — take notes."),
        ("Foundations — part 2", f"Continue lessons; practice exercises or examples related to {focus[0] if focus else 'basics'}."),
        ("Practice day", "Redo one lesson without help; fix mistakes and summarize key takeaways."),
        (
            "Deeper dive",
            f"Cover the next major topic ({focus[1] if len(focus) > 1 else 'next section'}) with 1–2 hours of focus.",
        ),
        ("Mini project / quiz", "Complete a quiz, assignment, or small project from the course if available."),
        ("Review & next steps", "Review the week, list 3 weak spots, and plan what to study next from the same course."),
    ]
    plan = []
    for i, day in enumerate(days):
        topic, goal = steps[i] if i < len(steps) else ("Review", "Consolidate learning.")
        plan.append({
            "day": day,
            "topic": topic,
            "goal": goal,
            "resource": course_url,
        })
    return plan


def match_jobs_to_user(user_skills: List[str], jobs: List[Dict]) -> List[Dict]:
    """Rank jobs by skill overlap. Uses embeddings if model available."""
    model = _get_model()
    user_skills_lower = [s.lower() for s in user_skills]

    if model and jobs:
        try:
            user_text = " ".join(user_skills_lower)
            user_emb = model.encode(user_text)
            scored = []
            for job in jobs:
                job_text = " ".join(job.get("skills_required", [])) + " " + job.get("title", "")
                job_emb = model.encode(job_text)
                score = _cosine_similarity(user_emb, job_emb)
                scored.append((score, job))
            scored.sort(key=lambda x: x[0], reverse=True)
            return [j for _, j in scored]
        except Exception as e:
            print(f"Embedding match failed, falling back to keyword: {e}")

    # Keyword fallback
    def overlap_score(job):
        req = [s.lower() for s in job.get("skills_required", [])]
        return len(set(user_skills_lower) & set(req))

    return sorted(jobs, key=overlap_score, reverse=True)


def generate_career_analysis(
    skills: List[str],
    interests: List[str],
    education: str,
    work_experience: str,
    state: str,
    language: str,
) -> Dict[str, Any]:
    gap_info = detect_skill_gaps(skills, interests)
    weekly_plan = generate_weekly_plan(skills, interests)
    trending = get_trending_fields(state or "default")

    roadmap = [
        f"Step 1: Strengthen core skills – {', '.join((skills or ['your current skills'])[:3])}",
        f"Step 2: Learn in-demand skills – {', '.join(gap_info['suggested_skills'][:3] or ['communication', 'problem-solving'])}",
        f"Step 3: Build real-world projects to showcase your abilities",
        f"Step 4: Apply for entry-level positions in {gap_info['career_direction']}",
        f"Step 5: Continuously upskill – explore {', '.join(trending[:2])} in your region",
    ]

    return {
        "skill_gaps": gap_info["skill_gaps"],
        "suggested_skills": gap_info["suggested_skills"],
        "career_direction": gap_info["career_direction"],
        "learning_roadmap": roadmap,
        "recommended_courses": [c["title"] for c in gap_info["courses"]],
        "weekly_plan": weekly_plan,
        "trending_fields": trending,
    }


def answer_career_question(question: str, user_skills: List[str], language: str) -> str:
    q = question.lower()
    if "job" in q or "career" in q:
        return (
            f"Based on your skills ({', '.join(user_skills[:3]) or 'your profile'}), "
            f"I recommend exploring roles in Software Development, Data Analysis, or Sales. "
            f"Focus on building a strong portfolio and networking."
        )
    elif "course" in q or "learn" in q:
        return (
            "Great question! I recommend starting with free resources on YouTube, "
            "then moving to structured courses on Coursera or Udemy. "
            "Consistency is key — aim for 1–2 hours of learning daily."
        )
    elif "skill" in q or "gap" in q:
        return (
            "Skill gaps are opportunities! Identify the top skills required in your target role "
            "and create a 4-week learning plan to address each one systematically."
        )
    elif "salary" in q or "pay" in q:
        return (
            "Salaries vary by role and location. Entry-level IT roles in India typically "
            "range from ₹3–6 LPA, while experienced professionals can earn ₹10–25+ LPA. "
            "Focus on building skills first — the pay follows."
        )
    else:
        return (
            "I'm NaviBot, your AI career guide! I can help with career recommendations, "
            "course suggestions, skill gap analysis, and job matching. What would you like to explore?"
        )
