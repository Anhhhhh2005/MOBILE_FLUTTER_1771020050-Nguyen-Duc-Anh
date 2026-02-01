@echo off
echo ========================================
echo   Import Database vao PostgreSQL
echo ========================================
echo.

cd /d "%~dp0"

echo Dang import schema vao PostgreSQL...
echo.
echo Password PostgreSQL: 10062005
echo.

psql -U postgres -f database_schema.sql

if errorlevel 1 (
    echo.
    echo ERROR: Import that bai!
    echo.
    echo Neu chua cai PostgreSQL command line tools:
    echo 1. Mo pgAdmin
    echo 2. Right-click database "pcm734database" -^> CREATE  
    echo 3. Query Tool -^> Open file "database_schema.sql"
    echo 4. Execute (F5)
    echo.
) else (
    echo.
    echo ========================================
   echo   THANH CONG!
    echo ========================================
    echo.
    echo Database "pcm734database" da duoc tao!
    echo.
)

pause
