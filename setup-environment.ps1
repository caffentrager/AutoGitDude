<#
  setup-environment.ps1
  목적: Windows에서 Chocolatey 설치(없을 경우), choco로 git/gh/msys2 설치, 그리고 필요한 경로를 Machine PATH에 추가

  사용법(관리자 권한 권장):
    PowerShell에서 관리자 권한으로 실행 후:
      .\setup-environment.ps1

  파라미터:
    -InstallChocolatey (default: true)
    -InstallGit (default: true)
    -InstallGh (default: true)
    -InstallMsys2 (default: true)

  주의: 이 스크립트는 머신 환경변수(Path) 수정(관리자 권한 필요)을 시도합니다.
#>

param(
    [bool]$InstallChocolatey = $true,
    [bool]$InstallGit = $true,
    [bool]$InstallGh = $true,
    [bool]$InstallMsys2 = $true
)

function Add-ToUserPath {
    param([string]$NewPath)
    if (-not (Test-Path -Path $NewPath -PathType Any)) {
        Write-Host "경로가 존재하지 않습니다: $NewPath" -ForegroundColor Yellow
        return
    }
    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ($current -and ($current -like "*${NewPath}*")) {
        Write-Host "이미 User PATH에 포함됨: $NewPath"
        return
    }
    $separator = ';'
    if (-not $current) { $current = '' }
    $newValue = $current.TrimEnd($separator)
    if ($newValue -ne '') { $newValue = $newValue + $separator }
    $newValue = $newValue + $NewPath
    try {
        [Environment]::SetEnvironmentVariable('Path', $newValue, 'User')
        Write-Host "User PATH에 추가됨: $NewPath"
    }
    catch {
        Write-Host "User PATH에 추가하는데 실패했습니다: $_" -ForegroundColor Red
    }
}

Write-Host '주의: 이 스크립트는 기본적으로 사용자(User) 범위의 PATH를 수정합니다. 일부 설치(예: Chocolatey)는 관리자 권한이 필요할 수 있습니다.' -ForegroundColor Yellow

Write-Host "== 시작: 환경 구성 스크립트 ==" -ForegroundColor Cyan

# 1) Chocolatey 설치 (없을 때)
if ($InstallChocolatey) {
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "Chocolatey가 설치되어 있지 않습니다. 설치를 시도합니다 (관리자 권한 필요할 수 있음)..." -ForegroundColor Green
        Set-ExecutionPolicy Bypass -Scope Process -Force
        try {
            $scriptText = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
            Invoke-Expression $scriptText
            Write-Host "Chocolatey 설치 시도 완료." -ForegroundColor Green
        }
        catch {
            Write-Host "Chocolatey 설치 실패(관리자 권한 필요할 수 있음): $_" -ForegroundColor Red
            Write-Host "관리자 권한으로 설치하거나 수동 설치 후 스크립트를 다시 실행하세요." -ForegroundColor Yellow
        }
        # refreshenv가 사용 가능하면 실행
        if (Get-Command refreshenv -ErrorAction SilentlyContinue) { refreshenv }
    }
    else {
        Write-Host "Chocolatey가 이미 설치되어 있습니다." -ForegroundColor Yellow
    }
}

# Helper: run choco install if available
function Install-ChocoPackage {
    param(
        [string]$PackageName
    )
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "choco 명령을 찾을 수 없습니다. Chocolatey가 제대로 설치되어 있는지 확인하세요." -ForegroundColor Red
        return
    }
    try {
        $installed = choco list --localonly --exact $PackageName | Select-String "^$PackageName " -Quiet
    }
    catch {
        $installed = $false
    }
    if ($installed) {
        Write-Host "$PackageName(은)는 이미 설치되어 있습니다." -ForegroundColor Yellow
    }
    else {
        Write-Host "$PackageName 설치 중..." -ForegroundColor Green
        choco install $PackageName -y --no-progress
    }
}

# 2) git 설치
if ($InstallGit) {
    Install-ChocoPackage -PackageName 'git'
}

# 3) gh(GitHub CLI) 설치
if ($InstallGh) {
    Install-ChocoPackage -PackageName 'gh'
}

# 4) msys2 설치
if ($InstallMsys2) {
    Install-ChocoPackage -PackageName 'msys2'

    # msys2의 bin 경로 후보들
    $candidates = @(
        'C:\tools\msys2\usr\bin',
        'C:\msys64\usr\bin',
        (Join-Path $env:ChocolateyInstall 'lib\msys2\tools\msys2\usr\bin')
    )
    $found = $null
    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { $found = $p; break }
    }
    if (-not $found) {
        # 탐색: C:\tools\ 또는 chocolatey 폴더
        $alt = Get-ChildItem -Path 'C:\' -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'msys' } | Select-Object -First 1
        if ($alt) {
            $trial = Join-Path $alt.FullName 'usr\bin'
            if (Test-Path $trial) { $found = $trial }
        }
    }
    if ($found) {
        Write-Host "MSYS2 바이너리 경로 발견: $found" -ForegroundColor Green
        Add-ToUserPath -NewPath $found
    }
    else {
        Write-Host "MSYS2 설치 후 bin 경로를 찾지 못했습니다. 수동으로 경로를 확인하여 PATH에 추가하세요." -ForegroundColor Yellow
    }
}

# git, gh 경로가 자동으로 PATH에 추가되지 않았다면 탐색 후 추가
try {
    # git 경로
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        $gitCandidate = 'C:\Program Files\Git\cmd'
        if (Test-Path $gitCandidate) { Add-ToUserPath -NewPath $gitCandidate }
    }
    # gh는 choco가 자동으로 경로에 추가하지만 안전장치
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghCmd) {
        $ghCandidate = Join-Path $env:ProgramFiles 'GitHub CLI'
        if (Test-Path $ghCandidate) { Add-ToUserPath -NewPath $ghCandidate }
    }
}
catch {
    Write-Host "경로 탐색 중 오류: $_" -ForegroundColor Red
}

Write-Host '== 완료: 설치/환경 설정이 끝났습니다. 쉘을 재시작하거나 로그아웃/로그인하여 PATH 변경을 반영하세요. ==' -ForegroundColor Cyan

# 요약 출력
Write-Host "Installed components summary:" -ForegroundColor Cyan
Get-Command choco, git, gh -ErrorAction SilentlyContinue | ForEach-Object { Write-Host " - $($_.Name): $($_.Source)" }

Write-Host "Machine PATH 마지막 3개 항목:" -ForegroundColor Cyan
$pathItems = [Environment]::GetEnvironmentVariable('Path','Machine').Split(';') | Where-Object { $_ -ne '' }
$pathItems[-3..-1] | ForEach-Object { Write-Host " - $_" }

# 끝