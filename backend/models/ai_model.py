from pydantic import BaseModel
from typing import Optional, List

class AIAnalysisRequest(BaseModel):
    uid: str
    skills: List[str]
    interests: List[str]
    education: Optional[str] = None
    work_experience: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    language: str = "English"

class AIAnalysisResponse(BaseModel):
    skill_gaps: List[str]
    suggested_skills: List[str]
    career_direction: str
    learning_roadmap: List[str]
    recommended_courses: List[str]
    weekly_plan: List[dict]

class ChatRequest(BaseModel):
    uid: str
    message: str
    language: str = "English"

class ChatResponse(BaseModel):
    reply: str
