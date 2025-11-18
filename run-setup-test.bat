@echo off
REM run-setup-test.bat
REM 관리자 권한으로 setup-environment.ps1을 실행하도록 시도합니다.
REM UAC 승인이 거부되거나 Elevation 실패 시에는 ExecutionPolicy만 우회하여 비관리자 모드로 실행합니다.

:: 스크립트가 위치한 디렉터리
SET "SCRIPT_DIR=%~dp0"

echo 실행: 관리자 권한으로 스크립트 실행을 시도합니다...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%setup-environment.ps1\" -InstallMSYS True -InstallMingw True' -Wait"
IF %ERRORLEVEL% NEQ 0 (
    echo 관리자 실행이 실패했거나 취소되었습니다. ExecutionPolicy 우회로 비관리자 모드에서 실행합니다...
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-environment.ps1" -InstallMSYS True -InstallMingw True
)

pause
exit /b %ERRORLEVEL%
