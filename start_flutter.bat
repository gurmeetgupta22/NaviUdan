@echo off
echo ========================================
echo   NaviUdan Flutter App - Starting
echo ========================================
cd /d "%~dp0naviudan_app"
echo Getting Flutter packages...
flutter pub get
echo.
echo Starting Flutter app...
echo (Connect a device or start an emulator first)
echo.
flutter run
pause
