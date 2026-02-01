@echo off
echo ========================================
echo   Chay Backend API - PCM 734
echo ========================================
echo.

cd /d "%~dp0"

echo Dang khoi dong backend...
echo API se chay tai:
echo   - HTTP:  http://localhost:5001
echo   - HTTPS: https://localhost:5002
echo   - Swagger: https://localhost:5002/swagger
echo.
echo Nhan Ctrl+C de dung backend
echo.

dotnet run

pause
