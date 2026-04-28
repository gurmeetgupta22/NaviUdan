from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from services.firebase_service import initialize_firebase
from routers import auth, users, jobs, courses, ai_bot

app = FastAPI(
    title="NaviUdan API",
    description="AI-Powered Skill & Employment Platform – SDG 1: No Poverty",
    version="1.0.0",
)

# CORS – allow mobile app and local testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize Firebase on startup
@app.on_event("startup")
async def startup_event():
    initialize_firebase()
    print("✅ NaviUdan Backend started successfully")

# Health check
@app.get("/", tags=["Health"])
async def root():
    return {
        "app": "NaviUdan API",
        "version": "1.0.0",
        "status": "running",
        "sdg": "SDG 1 – No Poverty",
    }

@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok"}

# Register routers
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(jobs.router)
app.include_router(courses.router)
app.include_router(ai_bot.router)
