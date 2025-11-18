@echo off
REM run-setup-test.bat
REM 테스트 전용 배치: ExecutionPolicy를 우회하여 스크립트를 실행하되,
REM 기본적으로 실제 패키지 설치는 하지 않도록 설치 플래그를 모두 false로 설정합니다.
REM 사용법: 더블클릭하거나 관리자 권한으로 cmd에서 실행하세요.

:: 이 파일이 있는 디렉터리
SET "SCRIPT_DIR=%~dp0"

:: 안전 모드: 설치 동작을 모두 비활성화하여 테스트 실행만 수행합니다.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-Location -LiteralPath '%SCRIPT_DIR%'; Write-Host 'Running setup-environment.ps1 in SAFE TEST mode (no installs)'; & '%SCRIPT_DIR%setup-environment.ps1' -InstallChocolatey:$false -InstallGit:$false -InstallGh:$false -InstallMSYS:$false -InstallMingw:$false"

pause
exit /b %ERRORLEVEL%