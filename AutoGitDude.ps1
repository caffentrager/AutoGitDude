<#
    AutoGitDude 초기 스크립트
    목적: 샘플 PowerShell 스크립트 파일
#>

Write-Output "Hello from AutoGitDude"

# 간단한 함수 예시
function Show-Info {
    param([string]$Message = "AutoGitDude running")
    Write-Output $Message
}

# 실행 예
Show-Info "Repository initialized"