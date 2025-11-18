@echo off
rem run-setup-msys.bat - Runs scripts\setup-msys.ps1; tries non-elevated first, then elevates if needed
setlocal
set "SCRIPT_DIR=%~dp0"
set "PSFILE=%SCRIPT_DIR%scripts\setup-msys.ps1"
set "LOGFILE=%SCRIPT_DIR%msys-install.log"

echo Running MSYS2 setup script (log: %LOGFILE%)
powershell -NoProfile -ExecutionPolicy Bypass -File "%PSFILE%" -AutoConfirm -LogFile "%LOGFILE%"
if %ERRORLEVEL% EQU 0 (
    echo Setup completed successfully.
    exit /b 0
)

echo Non-elevated run failed or returned non-zero. Attempting to elevate (UAC will prompt)...
echo --- 디버깅: 오류 메시지를 확인하려면 아무 키나 누르세요 ---
pause

powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%PSFILE%\" -AutoConfirm -LogFile \"%LOGFILE%\"' -Verb RunAs"

echo --- 작업 완료(또는 UAC로 새로운 창이 열림). 디버깅을 위해 아무 키나 누르세요 ---
pause
exit /b %ERRORLEVEL%
