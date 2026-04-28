from fastapi import APIRouter, HTTPException
from models.user_model import UserProfileCreate, UserProfileUpdate
from services.firebase_service import save_document, get_document, update_document

router = APIRouter(prefix="/users", tags=["Users"])

@router.post("/profile")
async def create_or_update_profile(profile: UserProfileCreate):
    """Create or update user profile in Firestore."""
    try:
        data = profile.model_dump()
        await save_document("users", profile.uid, data)
        return {"message": "Profile saved successfully", "uid": profile.uid}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/profile/{uid}")
async def get_profile(uid: str):
    """Fetch user profile from Firestore."""
    data = await get_document("users", uid)
    if not data:
        raise HTTPException(status_code=404, detail="User profile not found")
    return data

@router.patch("/profile/{uid}")
async def update_profile(uid: str, update: UserProfileUpdate):
    """Partially update user profile."""
    existing = await get_document("users", uid)
    if not existing:
        raise HTTPException(status_code=404, detail="User not found")
    
    update_data = {k: v for k, v in update.model_dump().items() if v is not None}
    await update_document("users", uid, update_data)
    return {"message": "Profile updated", "uid": uid}
