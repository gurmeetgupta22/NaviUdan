from pydantic import BaseModel
from typing import Optional, List

class Course(BaseModel):
    id: Optional[str] = None
    title: str
    description: str
    platform: str          # YouTube, Coursera, Udemy
    url: str
    language: str = "English"
    tags: List[str] = []
    is_free: bool = True
    duration: Optional[str] = None

class CourseRecommendationRequest(BaseModel):
    uid: str
    skills: List[str]
    interests: List[str]
    language: str = "English"
