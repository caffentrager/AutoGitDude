<#
  scripts/login-from-userdata.ps1
    목적: 리포지터리 루트의 userdata.login(JSON)을 읽어
        - git user.name / user.email 설정
        - git credential.helper 설정(옵션)
        - gh CLI에 웹 기반 로그인 흐름을 안내/실행 (토큰 저장 사용을 권장하지 않음)

  주의: userdata.login에는 개인 토큰이 평문으로 들어갈 수 있습니다. 보안상 권장하지 않음.
    - 권장: 환경변수(GH_TOKEN) 사용 또는 gh auth login --web 사용
    - 이 스크립트는 사용자가 명시적으로 파일에 토큰을 넣었을 때만 자동 로그인합니다.

  사용법:
    # 기본 경로(리포지터리 루트의 userdata.login)를 사용
    .\scripts\login-from-userdata.ps1

    # 다른 경로를 지정
    .\scripts\login-from-userdata.ps1 -Path 'C:\safe\userdata.login'
#>

param(
    [string]$Path = (Join-Path $PSScriptRoot '..\userdata.login'),
    [switch]$Force  # 이미 설정된 값을 덮어쓸지 여부
)

# 공통 유틸 로드 (Write-Log 등)
. "$PSScriptRoot\..\lib\common.ps1"

if (-not (Test-Path -Path $Path)) {
    Write-Log "userdata.login 파일을 찾을 수 없습니다. 템플릿을 생성합니다: $Path" 'WARN'
        $template = @'
    {
        "git": {
            "name": "Your Name",
            "email": "you@example.com"
        },
        "notes": "이 파일은 민감 정보를 포함할 수 있습니다. 실사용 시에는 저장소에 커밋하지 마세요. 권장 로그인 방법: gh auth login --web (브라우저 기반 인증)."
    }
    '@
    try {
        $dir = Split-Path -Path $Path -Parent
        if (-not (Test-Path $dir)) { New-Item -Path $dir -ItemType Directory -Force | Out-Null }
        Set-Content -Path $Path -Value $template -Encoding UTF8
        Write-Log "템플릿이 생성되었습니다. 파일을 편집하여 값을 입력한 뒤 다시 실행하세요." 'INFO'
    }
    catch {
        Write-Log "userdata.login 템플릿 생성 실패: $_" 'ERROR'
    }
    exit 0
}

# 읽기
try {
    $raw = Get-Content -Raw -Path $Path -ErrorAction Stop
    $data = $raw | ConvertFrom-Json
}
catch {
    Write-Log "userdata.login 읽기/파싱 실패: $_" 'ERROR'
    exit 1
}

# Git 설정
if ($data.git) {
    if ($data.git.name) {
        $existing = git config --global user.name 2>$null
        if (-not $existing -or $Force) {
            git config --global user.name "${($data.git.name)}"
            Write-Log "git user.name 설정: $($data.git.name)" 'INFO'
        }
        else { Write-Log "git user.name 이미 설정되어 있음(스킵): $existing" 'WARN' }
    }
    if ($data.git.email) {
        $existing = git config --global user.email 2>$null
        if (-not $existing -or $Force) {
            git config --global user.email "${($data.git.email)}"
            Write-Log "git user.email 설정: $($data.git.email)" 'INFO'
        }
        else { Write-Log "git user.email 이미 설정되어 있음(스킵): $existing" 'WARN' }
    }
    # credential.helper 설정 권장
    if ($data.git.credentialHelper) {
        git config --global credential.helper "${($data.git.credentialHelper)}"
        Write-Log "git credential.helper 설정: $($data.git.credentialHelper)" 'INFO'
    }
    else {
        # 기본값 권장: manager-core (Windows)
        try {
            git config --global credential.helper manager-core
            Write-Log "git credential.helper를 'manager-core'로 설정했습니다." 'INFO'
        } catch { }
    }
}
else { Write-Log "userdata.login에 'git' 섹션이 없습니다." 'WARN' }

# gh 로그인 (브라우저 기반, 토큰 저장 사용 안함)
if (Get-Command gh -ErrorAction SilentlyContinue) {
    try {
        Write-Log "gh로 웹 기반 로그인 흐름을 시작합니다 (브라우저에서 인증)." 'INFO'
        # --hostname은 필요에 따라 조정 가능
        & gh auth login --hostname github.com --web
        Write-Log "gh 로그인 흐름이 완료되었습니다. (성공/취소는 브라우저에서 결정됩니다)" 'INFO'
    }
    catch {
        Write-Log "gh 로그인 중 오류: $_" 'ERROR'
    }
}
else {
    Write-Log "gh CLI를 찾을 수 없습니다. gh 설치 후 다시 시도하세요." 'ERROR'
}

Write-Log "작업이 완료되었습니다." 'INFO'
