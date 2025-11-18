<#
  scripts/login-from-userdata.ps1
    목적: userdata 파일 읽기 로직 제거.
    이제 이 스크립트는 단순히 GitHub CLI의 브라우저 기반 로그인 흐름을 실행합니다:
      -> `gh auth login --web`

    사용법:
      .\scripts\login-from-userdata.ps1
#>

# 공통 유틸 로드(선택적). 없으면 간단한 Write-Log 대체를 사용.
$common = Join-Path $PSScriptRoot '..\lib\common.ps1'
if (Test-Path $common) { . $common }
else {
    function Write-Log { param($Message, $Level = 'INFO') Write-Host "[$Level] $Message" }
}

Write-Log "브라우저 기반 GitHub 로그인 흐름으로 전환합니다. 브라우저에서 인증을 완료하세요." 'INFO'

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Log "'gh' 명령을 찾을 수 없습니다. 먼저 GitHub CLI를 설치하세요: https://cli.github.com/" 'ERROR'
    exit 1
}

try {
    # --web 옵션을 사용하면 기본 브라우저에서 인증을 진행합니다.
    & gh auth login --web
    if ($LASTEXITCODE -eq 0) {
        Write-Log "gh 웹 로그인 명령이 실행되었습니다. 브라우저에서 인증을 완료하세요." 'INFO'
    }
    else {
        Write-Log "gh 로그인 명령이 비정상 종료했습니다. 종료 코드: $LASTEXITCODE" 'ERROR'
        exit $LASTEXITCODE
    }
}
catch {
    Write-Log "gh 로그인 실행 중 오류: $_" 'ERROR'
    exit 1
}

Write-Log "로그인 절차가 종료되었습니다. 필요시 'git config --global user.name' 등을 수동으로 설정하세요." 'INFO'
