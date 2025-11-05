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
    [bool]$InstallMsys2 = $true
)

function Write-Log { param([string]$Message, [string]$Level = 'INFO')
    switch ($Level.ToUpper()) {
        'INFO' { Write-Host $Message -ForegroundColor Cyan }
        'WARN' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        default { Write-Host $Message }
    }
}



function Add-ToUserPath {
    param([Parameter(Mandatory = $true)][string]$NewPath)

    # 상태 추적 변수(글로벌)
    if (-not (Test-Path variable:AddedPaths)) { Set-Variable -Name AddedPaths -Value @() -Scope Script }
    if (-not (Test-Path variable:SkippedPaths)) { Set-Variable -Name SkippedPaths -Value @() -Scope Script }
    if (-not (Test-Path variable:FailedPaths)) { Set-Variable -Name FailedPaths -Value @() -Scope Script }

    if (-not (Test-Path -Path $NewPath -PathType Any)) {
        Write-Host "경로가 존재하지 않습니다: $NewPath" -ForegroundColor Yellow
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
        Write-Host "이미 User PATH에 포함됨(스킵): $full" -ForegroundColor Yellow
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
        Write-Host "User PATH에 추가됨: $full" -ForegroundColor Green
        $script:AddedPaths += $full

        # 현재 PowerShell 세션의 프로세스 PATH에도 즉시 반영하여 명령을 바로 사용할 수 있게 함
        try {
            $procPath = $env:Path
            $procItems = @()
            if ($procPath) { $procItems = $procPath.Split(';') | Where-Object { $_ -ne '' } }
            $existsInProc = $false
            foreach ($it in $procItems) {
                try { $itFull = (Get-Item -LiteralPath $it -ErrorAction SilentlyContinue).FullName } catch { $itFull = $it }
                if ($itFull -and ($itFull -ieq $full)) { $existsInProc = $true; break }
            }
            if (-not $existsInProc) {
                if ($env:Path -and ($env:Path -ne '')) { $env:Path = $env:Path + ';' + $full } else { $env:Path = $full }
                Write-Host "(세션) PATH에 즉시 추가됨: $full" -ForegroundColor Cyan
            }
        }
        catch {
            # 무시: 세션 PATH 반영 실패 시에는 사용자가 새 쉘을 열도록 안내
        }
        return $true
    }
    catch {
        Write-Host "User PATH에 추가하는데 실패했습니다: $_" -ForegroundColor Red
        $script:FailedPaths += $full
        return $false
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
        try {
            choco install $PackageName -y --no-progress
        }
        catch {
            Write-Host "choco 설치 명령이 실패했습니다: $_" -ForegroundColor Red
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
        Write-Host "MSYS2 바이너리 경로 발견: $found" -ForegroundColor Green
        [void](Add-ToUserPath -NewPath $found)
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
        if (Test-Path $gitCandidate) { [void](Add-ToUserPath -NewPath $gitCandidate) }
    }
    # gh는 choco가 자동으로 경로에 추가하지만 안전장치
    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghCmd) {
        $ghCandidate = Join-Path $env:ProgramFiles 'GitHub CLI'
        if (Test-Path $ghCandidate) { [void](Add-ToUserPath -NewPath $ghCandidate) }
    }
}
catch {
    Write-Host "경로 탐색 중 오류: $_" -ForegroundColor Red
}

# --------------------------------------------------
# 공통 설치 경로 검사 함수: 여러 흔한 위치를 검사하여 설치 경로를 반환
# --------------------------------------------------
function Get-CommonInstallPaths {
    param(
        [string[]]$Programs = @('choco','git','gh','msys2')
    )

    $results = @{}
    foreach ($prog in $Programs) {
        $found = $null
        $candidates = @()

        switch ($prog) {
            'choco' {
                if ($env:ChocolateyInstall) { $candidates += Join-Path $env:ChocolateyInstall 'bin' }
                $candidates += 'C:\ProgramData\chocolatey\bin'
            }
            'git' {
                $candidates += 'C:\Program Files\Git\cmd'
                $candidates += 'C:\Program Files (x86)\Git\cmd'
            }
            'gh' {
                $candidates += 'C:\Program Files\GitHub CLI'
                $candidates += 'C:\Program Files\GitHub CLI\bin'
            }
            'msys2' {
                $candidates += 'C:\msys64\usr\bin'
                $candidates += 'C:\tools\msys2\usr\bin'
            }
            default {
                # 빈 후보집합으로 시작
            }
        }

    # 일반적인 ProgramFiles 위치와 로컬 AppData 설치 경로도 추가
    if ($env:ProgramFiles) { $candidates += Join-Path $env:ProgramFiles $prog }
    if (${env:ProgramFiles(x86)}) { $candidates += Join-Path ${env:ProgramFiles(x86)} $prog }
    if ($env:LOCALAPPDATA) { $candidates += Join-Path $env:LOCALAPPDATA (Join-Path 'Programs' $prog) }

        # 후보 중 존재하는 첫 경로를 채택. 실행 파일 검색(과도한 재귀는 피함)
        foreach ($c in $candidates | Where-Object { $_ -and ($_ -ne '') } ) {
            try {
                if (Test-Path $c) { $found = (Get-Item -LiteralPath $c -ErrorAction SilentlyContinue).FullName; break }
            }
            catch { }

            # 경로가 없더라도 그 위치 아래에 <prog>.exe 같은 실행파일이 있는지 간단히 검사
            try {
                $parent = Split-Path -Path $c -Parent
                if ($parent -and (Test-Path $parent)) {
                    $match = Get-ChildItem -Path $parent -Filter "$prog*.exe" -File -ErrorAction SilentlyContinue | Select-Object -First 1
                    if ($match) { $found = $match.DirectoryName; break }
                }
            }
            catch { }
        }

        $results[$prog] = $found
    }
    return $results
}

# 검사 및 요약용 호출
$DetectedPrograms = Get-CommonInstallPaths -Programs @('choco','git','gh','msys2')

Write-Host "검출된 일반 설치 경로(Detection):" -ForegroundColor Cyan
foreach ($k in $DetectedPrograms.Keys) {
    $v = $DetectedPrograms[$k]
    if ($v) { Write-Host " - $k : $v" -ForegroundColor Green } else { Write-Host " - $k : (미검출)" -ForegroundColor Yellow }
}

# 자동 추가: 명령이 사용 불가능하면 검출된 경로를 User PATH에 추가 시도
foreach ($k in $DetectedPrograms.Keys) {
    $v = $DetectedPrograms[$k]
    if (-not $v) { continue }
    $cmd = Get-Command $k -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "$k 명령이 이미 사용 가능하므로 PATH 추가를 스킵합니다." -ForegroundColor Yellow
        continue
    }
    Write-Host "자동 추가 시도: $k 경로를 User PATH에 추가합니다: $v" -ForegroundColor Cyan
    [void](Add-ToUserPath -NewPath $v)

    # 만약 User PATH에는 있지만 현재 세션에서 명령을 찾을 수 없는 경우(또는 위에서 세션 반영이 실패했을 경우), 세션 PATH에 강제로 추가 시도
    try {
        $cmd2 = Get-Command $k -ErrorAction SilentlyContinue
        if (-not $cmd2) {
            # 세션 PATH에 경로가 없으면 추가
            $procItems = @()
            if ($env:Path) { $procItems = $env:Path.Split(';') | Where-Object { $_ -ne '' } }
            $inProc = $false
            foreach ($it in $procItems) {
                try { $itFull = (Get-Item -LiteralPath $it -ErrorAction SilentlyContinue).FullName } catch { $itFull = $it }
                if ($itFull -and ($itFull -ieq $v)) { $inProc = $true; break }
            }
            if (-not $inProc) {
                if ($env:Path -and ($env:Path -ne '')) { $env:Path = $env:Path + ';' + $v } else { $env:Path = $v }
                Write-Host "(세션) PATH에 강제 추가됨: $v" -ForegroundColor Cyan
            }

            # refreshenv 가능하면 시도
            if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
                try { refreshenv | Out-Null } catch { }
            }
        }
    }
    catch { }
}


Write-Host '== 완료: 설치/환경 설정이 끝났습니다. 쉘을 재시작하거나 로그아웃/로그인하여 PATH 변경을 반영하세요. ==' -ForegroundColor Cyan

# 요약 출력
Write-Host "Installed components summary:" -ForegroundColor Cyan

# 더 친절한 요약: 명령이 있으면 경로+버전(가능한 경우), 없으면 감지된 경로 출력
$programsToShow = @('choco','git','gh','msys2')
foreach ($p in $programsToShow) {
    $cmd = Get-Command $p -ErrorAction SilentlyContinue
    if ($p -ieq 'msys2') {
        # msys2는 'msys2'라는 단일 명령이 없으므로 bash/pacman 실행파일을 검사
        $det = $null
        if ($DetectedPrograms.ContainsKey('msys2')) { $det = $DetectedPrograms['msys2'] }
        $exeFound = $null
        if ($det) {
            foreach ($exeCandidate in @('bash.exe','usr\bin\bash.exe','pacman.exe')) {
                $candidatePath = Join-Path $det $exeCandidate
                if (Test-Path $candidatePath) { $exeFound = $candidatePath; break }
            }
        }
        if ($exeFound) {
            $ver = $null
            try {
                $out = & "$exeFound" --version 2>$null
                if ($out) {
                    # msys2(bash) prints multi-line license text; use the first non-empty line and limit length
                    $lines = ($out -split "\r?\n") | Where-Object { $_ -and ($_.Trim() -ne '') }
                    if ($lines.Count -gt 0) {
                        $first = $lines[0].Trim()
                        if ($first.Length -gt 140) { $ver = $first.Substring(0,140) + '...'} else { $ver = $first }
                    }
                }
            } catch { }
            if ($ver) { Write-Host " - msys2 : $exeFound - $ver" } else { Write-Host " - msys2 : $exeFound" }
        }
        else {
            if ($det) { Write-Host " - msys2 : (명령 없음) 검출된 경로 = $det" -ForegroundColor Yellow } else { Write-Host " - msys2 : (명령/경로 없음)" -ForegroundColor Yellow }
        }
        continue
    }

    if ($cmd) {
        # 시도: --version 호출
        $ver = $null
        try {
            $out = & $p --version 2>$null
            if ($out) {
                $verRaw = $out | Out-String
                $ver = ($verRaw -replace "(\r?\n)+", ' ') -replace '\s{2,}', ' '
                $ver = $ver.Trim()
            }
        } catch { }
        if ($ver) { Write-Host " - $p : $($cmd.Source) - $ver" } else { Write-Host " - $p : $($cmd.Source)" }
    }
    else {
        $det = $null
        if ($DetectedPrograms.ContainsKey($p)) { $det = $DetectedPrograms[$p] }
        if ($det) { Write-Host " - $p : (명령 없음) 검출된 경로 = $det" -ForegroundColor Yellow } else { Write-Host " - $p : (명령/경로 없음)" -ForegroundColor Yellow }
    }
}

Write-Host "추가된(Added) 경로:" -ForegroundColor Cyan
if (Test-Path variable:AddedPaths -ErrorAction SilentlyContinue -PathType Any) {
    $addedUnique = $script:AddedPaths | Where-Object { $_ } | Select-Object -Unique
    if ($addedUnique.Count -gt 0) { $addedUnique | ForEach-Object { Write-Host " - $_" } } else { Write-Host " - (없음)" }
} else { Write-Host " - (없음)" }

Write-Host "스킵된(Skipped) 경로(이미 존재):" -ForegroundColor Yellow
if (Test-Path variable:SkippedPaths -ErrorAction SilentlyContinue -PathType Any) {
    $skippedUnique = $script:SkippedPaths | Where-Object { $_ } | Select-Object -Unique
    if ($skippedUnique.Count -gt 0) { $skippedUnique | ForEach-Object { Write-Host " - $_" } } else { Write-Host " - (없음)" }
} else { Write-Host " - (없음)" }

Write-Host "실패(Failed) 경로(추가 실패 또는 오류):" -ForegroundColor Red
if (Test-Path variable:FailedPaths -ErrorAction SilentlyContinue -PathType Any) {
    $failedUnique = $script:FailedPaths | Where-Object { $_ } | Select-Object -Unique
    if ($failedUnique.Count -gt 0) { $failedUnique | ForEach-Object { Write-Host " - $_" } } else { Write-Host " - (없음)" }
} else { Write-Host " - (없음)" }

Write-Host "User PATH 최근 항목(요약):" -ForegroundColor Cyan
$pathItems = [Environment]::GetEnvironmentVariable('Path','User')
if ($pathItems) {
    $items = $pathItems.Split(';') | Where-Object { $_ -ne '' }
    if ($items.Count -ge 5) { $items[-5..-1] | ForEach-Object { Write-Host " - $_" } }
    else { $items | ForEach-Object { Write-Host " - $_" } }
}

# 끝

# 끝