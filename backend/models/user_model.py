from pydantic import BaseModel, EmailStr
from typing import Optional, List
from enum import Enum

class RoleEnum(str, Enum):
    job_finder = "job_finder"
    recruiter = "recruiter"

class AgeGroupEnum(str, Enum):
    teenager = "18-20"
    adult = "20-30"
    experienced = "30+"

class EducationStatusEnum(str, Enum):
    school = "school"
    college = "college"
    job = "job"
    other = "other"

class UserProfile(BaseModel):
    uid: str
    name: str
    phone: str
    email: Optional[str] = None
    preferred_language: str = "English"
    role: RoleEnum
    state: Optional[str] = None
    district: Optional[str] = None
    age_group: Optional[AgeGroupEnum] = None

    # Job Finder specific
    education_status: Optional[EducationStatusEnum] = None
    class_or_stream: Optional[str] = None
    skills: Optional[List[str]] = []
    interests: Optional[List[str]] = []
    work_experience: Optional[str] = None

    # Recruiter specific
    organization: Optional[str] = None
    required_skills: Optional[List[str]] = []

class UserProfileCreate(BaseModel):
    uid: str
    name: str
    phone: str
    email: Optional[str] = None
    preferred_language: str = "English"
    role: RoleEnum
    state: Optional[str] = None
    district: Optional[str] = None
    age_group: Optional[str] = None
    education_status: Optional[str] = None
    class_or_stream: Optional[str] = None
    skills: Optional[List[str]] = []
    interests: Optional[List[str]] = []
    work_experience: Optional[str] = None
    organization: Optional[str] = None
    required_skills: Optional[List[str]] = []

class UserProfileUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    preferred_language: Optional[str] = None
    state: Optional[str] = None
    district: Optional[str] = None
    skills: Optional[List[str]] = None
    interests: Optional[List[str]] = None
    work_experience: Optional[str] = None
