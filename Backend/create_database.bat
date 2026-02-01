@echo off
echo ========================================
echo   Tao Database SQLite cho PCM 734
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Kiem tra .NET SDK...
dotnet --version
if errorlevel 1 (
    echo ERROR: .NET SDK chua duoc cai dat hoac chua co trong PATH
    echo Vui long cai dat tu: https://dotnet.microsoft.com/download/dotnet/8.0
    pause
    exit /b 1
)
echo.

echo [2/5] Restore packages...
dotnet restore
if errorlevel 1 (
    echo ERROR: Restore that bai
    pause
    exit /b 1
)
echo.

echo [3/5] Cai dat EF Core Tools...
dotnet tool install --global dotnet-ef
echo.

echo [4/5] Tao migration...
dotnet ef migrations add InitialCreate
if errorlevel 1 (
    echo ERROR: Tao migration that bai
    pause
    exit /b 1
)
echo.

echo [5/5] Tao database va seed data...
dotnet ef database update
if errorlevel 1 (
    echo ERROR: Tao database that bai
    pause
    exit /b 1
)
echo.

echo ========================================
echo   THANH CONG!
echo ========================================
echo.
echo Database da duoc tao: Pcm734Database.db
echo.
echo Ban co the chay backend bang lenh:
echo   dotnet run
echo.
pause
