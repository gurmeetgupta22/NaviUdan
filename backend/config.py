import os
from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()

class Settings(BaseSettings):
    app_name: str = "NaviUdan API"
    debug: bool = True
    firebase_credentials_path: str = "./firebase_credentials.json"
    firebase_project_id: str = ""
    app_secret_key: str = "navuidan-secret-key-2024"
    openai_api_key: str = ""
    openrouter_api_key: str = ""
    openrouter_model: str = "openai/gpt-4o-mini"
    openrouter_site_url: str = ""
    openrouter_app_name: str = "NaviUdan"
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.0-flash"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
