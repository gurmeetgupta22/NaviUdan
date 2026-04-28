@echo off
echo ========================================
echo   NaviUdan Backend - Starting Server
echo ========================================
cd /d "%~dp0backend"
echo Installing dependencies...
py -m pip install -r requirements.txt -q
echo.
echo Starting FastAPI server on http://localhost:8000
echo API Docs available at http://localhost:8000/docs
echo.
py -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
