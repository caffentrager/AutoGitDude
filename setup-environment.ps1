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

[CmdletBinding()]
param(
    [bool]$InstallChocolatey = $true,
    [bool]$InstallGit = $true,
    [bool]$InstallGh = $true,
    [bool]$InstallMsys2 = $true,
    [string]$LogFile = '.\setup-environment.log',
    [switch]$Undo
)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = 'INFO'
    )
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$ts] [$Level] $Message"
    try {
        $dir = Split-Path -Path $LogFile -Parent
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $line | Out-File -FilePath $LogFile -Encoding utf8 -Append
    }
    catch {
        # 로그 파일에 쓸 수 없는 경우 무시하되 화면에는 출력
    }
    Write-Host $line
}



function Add-ToUserPath {
    param([Parameter(Mandatory = $true)][string]$NewPath)

    # 상태 추적 변수(글로벌)
    if (-not (Test-Path variable:AddedPaths)) { Set-Variable -Name AddedPaths -Value @() -Scope Script }
    if (-not (Test-Path variable:SkippedPaths)) { Set-Variable -Name SkippedPaths -Value @() -Scope Script }
    if (-not (Test-Path variable:FailedPaths)) { Set-Variable -Name FailedPaths -Value @() -Scope Script }

    if (-not (Test-Path -Path $NewPath -PathType Any)) {
        Write-Log "경로가 존재하지 않습니다: $NewPath" 'WARN'
        $script:FailedPaths += $NewPath
        return $false
    }

    try {
        $full = (Get-Item -LiteralPath $NewPath -ErrorAction Stop).FullName
    }
    catch {
        $full = $NewPath
    }

    $current = [Environment]::GetEnvironmentVariable('Path', 'User')
    $currentItems = @()
    if ($current) { $currentItems = $current.Split(';') | Where-Object { $_ -ne '' } }

    # Normalize comparison: case-insensitive exact match
    $exists = $false
    foreach ($it in $currentItems) {
        try { $itFull = (Get-Item -LiteralPath $it -ErrorAction SilentlyContinue).FullName } catch { $itFull = $it }
        if ($itFull -and ($itFull -ieq $full)) { $exists = $true; break }
    }

    if ($exists) {
        Write-Log "이미 User PATH에 포함됨(스킵): $full" 'WARN'
        $script:SkippedPaths += $full
        return $true
    }

    # Append safely
    $separator = ';'
    $newValue = ($currentItems -join $separator)
    if ($newValue -ne '') { $newValue = $newValue + $separator }
    $newValue = $newValue + $full
    try {
        [Environment]::SetEnvironmentVariable('Path', $newValue, 'User')
        Write-Log "User PATH에 추가됨: $full" 'INFO'
        $script:AddedPaths += $full
        return $true
    }
    catch {
        Write-Log "User PATH에 추가하는데 실패했습니다: $_" 'ERROR'
        $script:FailedPaths += $full
        return $false
    }
}

Write-Host '주의: 이 스크립트는 기본적으로 사용자(User) 범위의 PATH를 수정합니다. 일부 설치(예: Chocolatey)는 관리자 권한이 필요할 수 있습니다.' -ForegroundColor Yellow

Write-Host "== 시작: 환경 구성 스크립트 ==" -ForegroundColor Cyan
Write-Log "Script started. Log file: $LogFile" 'INFO'

    if ($Undo) { 
    Write-Log "Undo mode requested. Attempting to revert last added PATH entries from log: $LogFile" 'INFO'
    if (-not (Test-Path $LogFile)) {
        Write-Log "Log file not found: $LogFile" 'ERROR'
        exit 1
    }
    # Read log lines and find last JSON summary line
    $jsonLines = Get-Content -Path $LogFile -ErrorAction SilentlyContinue | Where-Object { $_ -match '^{"Timestamp' -or $_ -match '"Added":' }
    if (-not $jsonLines) {
        # try to find last line that looks like JSON
        $lastLine = Get-Content -Path $LogFile -ErrorAction SilentlyContinue | Select-Object -Last 1
    }
    else { $lastLine = $jsonLines | Select-Object -Last 1 }
    try {
        $record = $lastLine | ConvertFrom-Json -ErrorAction Stop
    }
    catch {
        Write-Log "로그에서 복원할 JSON 기록을 찾지 못했습니다. 수동으로 PATH를 편집하세요." 'ERROR'
        exit 1
    }
    if (-not $record.Added) {
        Write-Log "복원할 Added 경로가 없습니다." 'WARN'
        exit 0
    }
    $userPath = [Environment]::GetEnvironmentVariable('Path','User')
    $items = @()
    if ($userPath) { $items = $userPath.Split(';') | Where-Object { $_ -ne '' } }
    $removed = @()
    foreach ($p in $record.Added) {
        $match = $items | Where-Object { 
            try { (Get-Item -LiteralPath $_ -ErrorAction SilentlyContinue).FullName -ieq (Get-Item -LiteralPath $p -ErrorAction SilentlyContinue).FullName } catch { $_ -ieq $p }
        }
        if ($match) {
            $items = $items | Where-Object { $_ -notin $match }
            $removed += $match
        }
    }
    $newPath = $items -join ';'
    try {
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Log "Removed PATH entries: $($removed -join ', ')" 'INFO'
        Write-Log "Undo completed." 'INFO'
        exit 0
    }
    catch {
        Write-Log "Undo failed: $_" 'ERROR'
        exit 1
    }
}

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
        Write-Log "$PackageName(은)는 이미 설치되어 있습니다." 'WARN'
    }
    else {
        Write-Host "$PackageName 설치 중..." -ForegroundColor Green
        try {
            choco install $PackageName -y --no-progress
        }
        catch {
            Write-Log "choco 설치 명령이 실패했습니다: $_" 'ERROR'
        }
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
    $candidates = @('C:\tools\msys2\usr\bin','C:\msys64\usr\bin')
    if ($env:ChocolateyInstall) {
        $chocoMsysPath = Join-Path $env:ChocolateyInstall 'lib\msys2\tools\msys2\usr\bin'
        $candidates += $chocoMsysPath
    }
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
            Write-Log "MSYS2 바이너리 경로 발견: $found" 'INFO'
        Add-ToUserPath -NewPath $found
    }
    else {
            Write-Log "MSYS2 설치 후 bin 경로를 찾지 못했습니다. 수동으로 경로를 확인하여 PATH에 추가하세요." 'WARN'
    }

    # 추가 요청: C:\msys64 및 C:\msys64\usr\bin을 User PATH에 추가 시도
    $ensurePaths = @('C:\msys64', 'C:\msys64\usr\bin')
    foreach ($ep in $ensurePaths) {
        if (Test-Path $ep) {
            Add-ToUserPath -NewPath $ep
        }
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

Write-Host "추가된(Added) 경로:" -ForegroundColor Cyan
if (Test-Path variable:AddedPaths -ErrorAction SilentlyContinue -PathType Any) { $script:AddedPaths | ForEach-Object { Write-Host " - $_" } } else { Write-Host " - (없음)" }

Write-Host "스킵된(Skipped) 경로(이미 존재):" -ForegroundColor Yellow
if (Test-Path variable:SkippedPaths -ErrorAction SilentlyContinue -PathType Any) { $script:SkippedPaths | ForEach-Object { Write-Host " - $_" } } else { Write-Host " - (없음)" }

Write-Host "실패(Failed) 경로(추가 실패 또는 오류):" -ForegroundColor Red
if (Test-Path variable:FailedPaths -ErrorAction SilentlyContinue -PathType Any) { $script:FailedPaths | ForEach-Object { Write-Host " - $_" } } else { Write-Host " - (없음)" }

Write-Host "User PATH 최근 항목(요약):" -ForegroundColor Cyan
$pathItems = [Environment]::GetEnvironmentVariable('Path','User')
if ($pathItems) {
    $items = $pathItems.Split(';') | Where-Object { $_ -ne '' }
    if ($items.Count -ge 5) { $items[-5..-1] | ForEach-Object { Write-Host " - $_" } }
    else { $items | ForEach-Object { Write-Host " - $_" } }
}

# Write summary to log as JSON record (avoid inline 'if' expressions which can break in some PS versions)
$added = @()
$skipped = @()
$failed = @()
if (Test-Path variable:AddedPaths -ErrorAction SilentlyContinue) { $added = $script:AddedPaths }
if (Test-Path variable:SkippedPaths -ErrorAction SilentlyContinue) { $skipped = $script:SkippedPaths }
if (Test-Path variable:FailedPaths -ErrorAction SilentlyContinue) { $failed = $script:FailedPaths }

$summary = [PSCustomObject]@{
    Timestamp = (Get-Date).ToString('o')
    Added = $added
    Skipped = $skipped
    Failed = $failed
}
try {
    $json = $summary | ConvertTo-Json -Depth 5 -Compress
    $json | Out-File -FilePath $LogFile -Encoding utf8 -Append
    Write-Log "Summary appended to log: $LogFile" 'INFO'
}
catch {
    Write-Log "Summary write failed: $_" 'ERROR'
}

# 끝