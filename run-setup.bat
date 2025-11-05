@echo off
REM run-setup.bat
REM 이 배치 파일은 PowerShell 스크립트 실행 정책으로 인한 차단을 피하기 위해
REM setup-environment.ps1을 -ExecutionPolicy Bypass 옵션으로 실행합니다.
REM 사용법: 이 파일을 더블클릭하거나, 관리자 권한 cmd에서 실행하세요.

:: 스크립트가 위치한 디렉터리
SET "SCRIPT_DIR=%~dp0"

:: 기본: PowerShell 5.1에서 -File 및 -ExecutionPolicy Bypass를 사용하여 실행
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup-environment.ps1"

:: 대화형 편집/실행을 원하면 아래 대체 명령을 사용하세요(주석 해제):
:: powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location -LiteralPath '%SCRIPT_DIR%'; Start-Process powershell -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','%SCRIPT_DIR%setup-environment.ps1' -Verb RunAs"

pause
exit /b %ERRORLEVEL%
