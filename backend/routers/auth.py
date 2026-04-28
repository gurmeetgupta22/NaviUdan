from fastapi import APIRouter, HTTPException, Header
from typing import Optional
from services.firebase_service import verify_firebase_token

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/verify-token")
async def verify_token(authorization: Optional[str] = Header(None)):
    """Verify Firebase ID token sent from the mobile app."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid Authorization header")
    
    id_token = authorization.split("Bearer ")[1]
    try:
        decoded = await verify_firebase_token(id_token)
        return {
            "uid": decoded.get("uid"),
            "phone": decoded.get("phone_number"),
            "email": decoded.get("email"),
            "verified": True,
        }
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
