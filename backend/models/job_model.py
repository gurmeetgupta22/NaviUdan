from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum

class JobTypeEnum(str, Enum):
    full_time = "full_time"
    part_time = "part_time"
    internship = "internship"
    contract = "contract"

class JobCreate(BaseModel):
    recruiter_uid: str
    title: str
    description: str
    skills_required: List[str]
    salary: Optional[str] = None
    job_type: JobTypeEnum = JobTypeEnum.full_time
    location: str
    state: Optional[str] = None
    district: Optional[str] = None
    listing_days: int = Field(default=30, ge=1, le=365)

class Job(BaseModel):
    id: Optional[str] = None
    recruiter_uid: str
    title: str
    description: str
    skills_required: List[str]
    salary: Optional[str] = None
    job_type: JobTypeEnum = JobTypeEnum.full_time
    location: str
    state: Optional[str] = None
    district: Optional[str] = None
    is_active: bool = True
    listing_days: Optional[int] = None
    posted_at: Optional[str] = None
    expires_at: Optional[str] = None

class JobApplication(BaseModel):
    job_id: str
    applicant_uid: str
    application_text: Optional[str] = None
    attachments: List[str] = []
    status: str = "pending"  # pending, accepted, rejected

class ApplicationStatusUpdate(BaseModel):
    status: str  # accepted | rejected
