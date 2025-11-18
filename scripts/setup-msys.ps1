<#
  scripts/setup-msys.ps1
  목적: Windows에서 MSYS2를 설치하고 pacman으로 msys 런타임과 mingw 툴체인을 설치한 뒤
        mingw의 bin 폴더를 User PATH에 추가하여 gcc/g++ 등을 사용할 수 있게 합니다.

  사용법(관리자 권장):
    PowerShell 관리자 쉘에서:
      .\scripts\setup-msys.ps1

  옵션:
    -AutoConfirm : 모든 프롬프트를 자동으로 Yes 처리합니다 (CI/자동화용)

  주의:
    - 이 스크립트는 Chocolatey가 설치되어 있어야 choco를 통해 MSYS2를 설치합니다.
    - 관리자 권한이 필요한 단계가 있습니다(pacman 초기 업데이트 등).
    - 실제 설치는 시스템 환경을 변경하므로 신뢰된 환경에서 실행하세요.
#>

[CmdletBinding()]
param(
    [switch]$AutoConfirm,
    [string]$LogFile
)

# 전역 로그 파일 변수
$Global:ScriptLogFile = $LogFile

function Write-Log { param([string]$Message, [string]$Level = 'INFO')
    $time = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$time] [$Level] $Message"
    switch ($Level.ToUpper()) {
        'INFO' { Write-Host $line -ForegroundColor Cyan }
        'WARN' { Write-Host $line -ForegroundColor Yellow }
        'ERROR' { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line }
    }
    if ($Global:ScriptLogFile) {
        try { $line | Out-File -FilePath $Global:ScriptLogFile -Encoding utf8 -Append -ErrorAction SilentlyContinue } catch {}
    }
}

function Prompt-YesNo([string]$Message, [bool]$Default=$false) {
    if ($AutoConfirm) { return $true }
    try {
        $r = Read-Host "$Message (Y/N)"
        if (-not $r) { return $Default }
        return $r.Trim().ToUpper().StartsWith('Y')
    }
    catch { return $Default }
}

function Add-UserPathIfMissing([string]$NewPath) {
    try {
        if (-not (Test-Path -Path $NewPath -PathType Container)) { return $false }
        $current = [Environment]::GetEnvironmentVariable('Path','User')
        $items = @()
        if ($current) { $items = $current.Split(';') | Where-Object { $_ -ne '' } }
        foreach ($it in $items) { if ($it.Trim().ToLower() -eq $NewPath.Trim().ToLower()) { return $true } }
        $newValue = if ($current -and $current -ne '') { $current + ';' + $NewPath } else { $NewPath }
        [Environment]::SetEnvironmentVariable('Path', $newValue, 'User')
        Write-Log "User PATH에 추가됨: $NewPath" 'INFO'
        return $true
    }
    catch { Write-Log "Path 추가 실패: $_" 'ERROR'; return $false }
}

Write-Log "== 시작: setup-msys.ps1 ==" 'INFO'

# 1) choco 존재 확인
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Chocolatey(choco)를 찾을 수 없습니다. 먼저 choco를 설치하세요." 'ERROR'
    exit 1
}

# 2) MSYS2 설치 (choco)
$msysPkg = 'msys2'
$installed = $false
try {
    $out = choco list --localonly --exact $msysPkg --limit-output 2>$null
    if ($out -and ($out -match "^$msysPkg\|")) { $installed = $true }
}
catch { $installed = $false }

if ($installed) {
    Write-Log "MSYS2가 이미 설치되어 있습니다." 'INFO'
}
else {
    if (-not (Prompt-YesNo "MSYS2 설치를 진행하시겠습니까?" $true)) { Write-Log "MSYS2 설치를 건너뜁니다." 'INFO'; exit 0 }
    Write-Log "MSYS2 설치 시작 (choco install msys2)..." 'INFO'
    try {
        choco install $msysPkg -y --no-progress
    }
    catch { Write-Log "MSYS2 설치 명령 실패: $_" 'ERROR'; exit 1 }
}

# 3) pacman 경로 탐색
$possiblePacman = @(
    'C:\msys64\usr\bin\pacman.exe',
    'C:\tools\msys64\usr\bin\pacman.exe',
    (Join-Path $env:LOCALAPPDATA 'Programs\msys2\usr\bin\pacman.exe')
)
$pacman = $null
foreach ($p in $possiblePacman) { if (Test-Path $p) { $pacman = $p; break } }

if (-not $pacman) {
    # try to find via where
    try { $where = & where.exe pacman 2>$null } catch { $where = $null }
    if ($where) { $pacman = $where.Split()[0] }
}

# Fallback: search under choco installation directory recursively (handles nested msys64/msys64)
if (-not $pacman -and (Test-Path 'C:\tools\msys64')) {
    try {
        $found = Get-ChildItem -Path 'C:\tools\msys64' -Filter pacman.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($found) { $pacman = $found.FullName }
    } catch {}
}

if (-not $pacman) { Write-Log "pacman을 찾을 수 없습니다. MSYS2 설치가 제대로 되었는지 확인하세요." 'ERROR'; exit 1 }

Write-Log "pacman 실행파일 발견: $pacman" 'INFO'

# 4) pacman으로 시스템 업데이트 및 msys/mingw 패키지 설치
if (-not (Prompt-YesNo "pacman으로 MSYS2 업데이트 및 mingw 툴체인 설치를 진행하시겠습니까? (관리자 권한 필요할 수 있음)" $true)) { Write-Log "pacman 단계 건너뜁니다." 'INFO' ; exit 0 }

    try {
        Write-Log "pacman 데이터베이스/패키지 업데이트 (may require admin)..." 'INFO'
        $retry = 0; $ok = $false
        while (-not $ok -and $retry -lt 3) {
            try { & $pacman -Syu --noconfirm | Out-Null; $ok = $true } catch { $retry++; Start-Sleep -Seconds (5 * $retry) }
        }
        if (-not $ok) { Write-Log "pacman -Syu 실패 (3회)" 'ERROR'; exit 1 }
        Start-Sleep -Seconds 2
        # Install msys runtime base packages and mingw toolchain with retry
        Write-Log "MSYS runtime 및 mingw-w64 툴체인 설치..." 'INFO'
        $retry = 0; $ok = $false
        while (-not $ok -and $retry -lt 3) {
            try { & $pacman -S --noconfirm msys2-runtime base-devel mingw-w64-x86_64-toolchain | Out-Null; $ok = $true } catch { $retry++; Start-Sleep -Seconds (5 * $retry) }
        }
        if (-not $ok) { Write-Log "pacman -S (toolchain) 실패 (3회)" 'ERROR'; exit 1 }
    }
    catch { Write-Log "pacman 실행 중 오류: $_" 'ERROR'; exit 1 }

# 5) mingw bin 경로를 PATH에 추가 (user)
$mingwBin = 'C:\msys64\mingw64\bin'
if (-not (Test-Path $mingwBin)) {
    # 다른 후보
    $alt = 'C:\msys64\usr\bin'
    if (Test-Path $alt) { $mingwBin = $alt }
}

if (Test-Path $mingwBin) {
    if (Add-UserPathIfMissing -NewPath $mingwBin) { Write-Log "mingw bin을 User PATH에 추가했습니다: $mingwBin" 'INFO' }
    else { Write-Log "mingw bin PATH 추가 실패 또는 이미 존재" 'WARN' }
}
else { Write-Log "mingw bin 경로를 찾을 수 없습니다: $mingwBin" 'WARN' }

# 6) 검증: gcc/g++ 확인
try {
    $gcc = Get-Command gcc -ErrorAction SilentlyContinue
    if (-not $gcc) {
        # MSYS2 환경에서는 Windows에서 바로 안 보일 수 있으므로 mingwBin 경로의 gcc 확인
        $gccPath = Join-Path $mingwBin 'gcc.exe'
        if (Test-Path $gccPath) { Write-Log "gcc가 발견됨: $gccPath" 'INFO' } else { Write-Log "gcc를 찾을 수 없습니다. 설치/PATH를 확인하세요." 'ERROR'; exit 1 }
    }
    else { Write-Log "gcc 사용 가능: $($gcc.Source)" 'INFO' }
}
catch { Write-Log "검증 중 오류: $_" 'ERROR'; exit 1 }

Write-Log "== 완료: MSYS2 및 mingw 설치/설정 완료 (검증됨) ==" 'INFO'

Exit 0
