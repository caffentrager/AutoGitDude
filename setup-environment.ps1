<#
  setup-environment.ps1
    목적: Windows에서 Chocolatey 설치(없을 경우), choco로 git/gh 설치, 그리고 필요한 경로를 Machine PATH에 추가

  사용법(관리자 권한 권장):
    PowerShell에서 관리자 권한으로 실행 후:
      .\setup-environment.ps1

  파라미터:
    -InstallChocolatey (default: true)
    -InstallGit (default: true)
    -InstallGh (default: true)

  주의: 이 스크립트는 머신 환경변수(Path) 수정(관리자 권한 필요)을 시도합니다.
#>



[CmdletBinding()]
param(
    [bool]$InstallChocolatey = $true,
    [bool]$InstallGit = $true,
    [bool]$InstallGh = $true,
    [bool]$InstallMSYS = $false,
    [bool]$InstallMingw = $false
)

function Write-Log { param([string]$Message, [string]$Level = 'INFO')
    switch ($Level.ToUpper()) {
        'INFO' { Write-Host $Message -ForegroundColor Cyan }
        'WARN' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        default { Write-Host $Message }
    }
}

# 공통 유틸리티 로드(Write-Log, Normalize-PathString 등)
. "$PSScriptRoot\lib\common.ps1"


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

    # Normalize 비교: Normalize-PathString 사용
    $exists = $false
    $normFull = Normalize-PathString $full
    foreach ($it in $currentItems) {
        $itNorm = Normalize-PathString $it
        if ($itNorm -and ($itNorm -eq $normFull)) { $exists = $true; break }
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

        # 현재 PowerShell 세션의 프로세스 PATH에도 즉시 반영하여 명령을 바로 사용할 수 있게 함
        try {
            $procPath = $env:Path
            $procItems = @()
            if ($procPath) { $procItems = $procPath.Split(';') | Where-Object { $_ -ne '' } }
            $existsInProc = $false
            $normFull = Normalize-PathString $full
            foreach ($it in $procItems) {
                $itNorm = Normalize-PathString $it
                if ($itNorm -and ($itNorm -eq $normFull)) { $existsInProc = $true; break }
            }
            if (-not $existsInProc) {
                if ($env:Path -and ($env:Path -ne '')) { $env:Path = $env:Path + ';' + $full } else { $env:Path = $full }
                Write-Log "(세션) PATH에 즉시 추가됨: $full" 'INFO'
            }
        }
        catch {
            # 무시: 세션 PATH 반영 실패 시에는 사용자가 새 쉘을 열도록 안내
        }
        return $true
    }
    catch {
        Write-Log "User PATH에 추가하는데 실패했습니다: $_" 'ERROR'
        $script:FailedPaths += $full
        return $false
    }
}

Write-Log '주의: 이 스크립트는 기본적으로 사용자(User) 범위의 PATH를 수정합니다. 일부 설치(예: Chocolatey)는 관리자 권한이 필요할 수 있습니다.' 'WARN'

Write-Log "== 시작: 환경 구성 스크립트 ==" 'INFO'

# 1) Chocolatey 설치 (강제): 이미 설치되어 있어도 업그레이드/재설치를 시도합니다.
if ($InstallChocolatey) {
    Write-Log "Chocolatey 설치 여부를 확인합니다. 설치되어 있으면 스킵합니다." 'INFO'

    $chocoCmd = Get-Command choco -ErrorAction SilentlyContinue
    if ($chocoCmd) {
        Write-Log "choco가 이미 설치되어 있습니다. 설치를 건너뜁니다." 'INFO'
    }
    else {
        Write-Log "choco가 발견되지 않아 설치를 시도합니다. (관리자 권한 필요할 수 있음)" 'INFO'
        Set-ExecutionPolicy Bypass -Scope Process -Force
        try {
            $installScript = (Invoke-WebRequest -Uri 'https://community.chocolatey.org/install.ps1' -UseBasicParsing -ErrorAction Stop).Content
            Invoke-Expression $installScript
            Write-Log "Chocolatey 설치 시도 완료." 'INFO'
        }
        catch {
            Write-Log "Chocolatey 설치 실패(관리자 권한 필요할 수 있음): $_" 'ERROR'
            Write-Log "관리자 권한으로 설치하거나 수동 설치 후 스크립트를 다시 실행하세요." 'WARN'
        }

        # refreshenv가 사용 가능하면 실행
        if (Get-Command refreshenv -ErrorAction SilentlyContinue) { try { refreshenv } catch { } }
    }
}

# Helper: run choco install if available
function Install-ChocoPackage {
    param(
        [string]$PackageName
    )
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Log "choco 명령을 찾을 수 없습니다. Chocolatey가 제대로 설치되어 있는지 확인하세요." 'ERROR'
        return
    }
    try {
        # --limit-output는 'package|version' 형식으로 출력하므로 이를 검사
        $installed = $false
        $out = choco list --localonly --exact $PackageName --limit-output 2>$null
        if ($out -and ($out -match "^$PackageName\|")) { $installed = $true }
    }
    catch {
        $installed = $false
    }
    if ($installed) {
        Write-Log "$PackageName(은)는 이미 설치되어 있습니다." 'WARN'
    }
    else {
        Write-Log "$PackageName 설치 중..." 'INFO'
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

# 4) Optional: MSYS2 설치 (선택)
if ($InstallMSYS) {
    Write-Log "MSYS2 설치 플래그가 설정되어 있습니다. Chocolatey를 통해 MSYS2 설치를 시도합니다." 'INFO'
    Install-ChocoPackage -PackageName 'msys2'
}

# 5) Optional: MinGW 설치 (선택)
if ($InstallMingw) {
    Write-Log "MinGW 설치 플래그가 설정되어 있습니다. Chocolatey를 통해 MinGW 설치를 시도합니다." 'INFO'
    # 패키지 이름은 배포에 따라 다를 수 있습니다. 일반적으로 'mingw' 또는 'mingw-w64' 패키지를 사용합니다.
    Install-ChocoPackage -PackageName 'mingw'
}

# (참고) 불필요한 오래된 설치 옵션 관련 로직은 제거되었습니다.

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
    Write-Log "경로 탐색 중 오류: $_" 'ERROR'
}

# --------------------------------------------------
# 공통 설치 경로 검사 함수: 여러 흔한 위치를 검사하여 설치 경로를 반환
# --------------------------------------------------
function Get-CommonInstallPaths {
    param(
    [string[]]$Programs = @('choco','git','gh')
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
                    'msys' {
                        $candidates += 'C:\msys64\usr\bin'
                        $candidates += 'C:\tools\msys64\usr\bin'
                        $candidates += Join-Path $env:LOCALAPPDATA 'Programs\msys2\usr\bin'
                    }
                    'mingw' {
                        $candidates += 'C:\mingw\bin'
                        $candidates += 'C:\Program Files\mingw-w64\mingw64\bin'
                        $candidates += 'C:\Program Files (x86)\mingw-w64\mingw32\bin'
                        $candidates += Join-Path $env:ProgramFiles 'mingw-w64\mingw64\bin'
                    }
            'gh' {
                $candidates += 'C:\Program Files\GitHub CLI'
                $candidates += 'C:\Program Files\GitHub CLI\bin'
            }
            # (과거) 일부 오래된 후보 경로는 현재 검사 대상에서 제외됨
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
$programsToDetect = @('choco','git','gh')
if ($InstallMSYS) { $programsToDetect += 'msys' }
if ($InstallMingw) { $programsToDetect += 'mingw' }
$DetectedPrograms = Get-CommonInstallPaths -Programs $programsToDetect

Write-Log "검출된 일반 설치 경로(감지):" 'INFO'
foreach ($k in $DetectedPrograms.Keys) {
    $v = $DetectedPrograms[$k]
    if ($v) { Write-Log " - $k : $v" 'INFO' } else { Write-Log " - $k : (미검출)" 'WARN' }
}

# 자동 추가: 명령이 사용 불가능하면 검출된 경로를 User PATH에 추가 시도
foreach ($k in $DetectedPrograms.Keys) {
    $v = $DetectedPrograms[$k]
    if (-not $v) { continue }
    $cmd = Get-Command $k -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Log "$k 명령이 이미 사용 가능하므로 PATH 추가를 스킵합니다." 'WARN'
        continue
    }
    Write-Log "자동 추가 시도: $k 경로를 User PATH에 추가합니다: $v" 'INFO'
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
                Write-Log "(세션) PATH에 강제 추가됨: $v" 'INFO'
            }

            # refreshenv 가능하면 시도
            if (Get-Command refreshenv -ErrorAction SilentlyContinue) {
                try { refreshenv | Out-Null } catch { }
            }
        }
    }
    catch { }
}


Write-Log '== 완료: 설치/환경 설정이 끝났습니다. 쉘을 재시작하거나 로그아웃/로그인하여 PATH 변경을 반영하세요. ==' 'INFO'

# 요약 출력
Write-Log "설치된 구성요약:" 'INFO'

# 더 친절한 요약: 명령이 있으면 경로+버전(가능한 경우), 없으면 감지된 경로 출력
$programsToShow = @('choco','git','gh')
foreach ($p in $programsToShow) {
    $cmd = Get-Command $p -ErrorAction SilentlyContinue
    # (특정 도구용 특수 요약 출력은 현재 제공하지 않습니다)

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
        if ($ver) { Write-Log " - $p : $($cmd.Source) - $ver" 'INFO' } else { Write-Log " - $p : $($cmd.Source)" 'INFO' }
    }
    else {
        $det = $null
        if ($DetectedPrograms.ContainsKey($p)) { $det = $DetectedPrograms[$p] }
        if ($det) { Write-Log " - $p : (명령 없음) 검출된 경로 = $det" 'WARN' } else { Write-Log " - $p : (명령/경로 없음)" 'WARN' }
    }
}

Write-Log "추가된(Added) 경로:" 'INFO'
if (Test-Path variable:AddedPaths -ErrorAction SilentlyContinue -PathType Any) {
    $addedUnique = $script:AddedPaths | Where-Object { $_ } | Select-Object -Unique
    if ($addedUnique.Count -gt 0) { $addedUnique | ForEach-Object { Write-Log " - $_" 'INFO' } } else { Write-Log " - (없음)" 'INFO' }
} else { Write-Log " - (없음)" 'INFO' }

Write-Log "스킵된(Skipped) 경로(이미 존재):" 'WARN'
if (Test-Path variable:SkippedPaths -ErrorAction SilentlyContinue -PathType Any) {
    $skippedUnique = $script:SkippedPaths | Where-Object { $_ } | Select-Object -Unique
    if ($skippedUnique.Count -gt 0) { $skippedUnique | ForEach-Object { Write-Log " - $_" 'WARN' } } else { Write-Log " - (없음)" 'WARN' }
} else { Write-Log " - (없음)" 'WARN' }

Write-Log "실패(Failed) 경로(추가 실패 또는 오류):" 'ERROR'
if (Test-Path variable:FailedPaths -ErrorAction SilentlyContinue -PathType Any) {
    $failedUnique = $script:FailedPaths | Where-Object { $_ } | Select-Object -Unique
    if ($failedUnique.Count -gt 0) { $failedUnique | ForEach-Object { Write-Log " - $_" 'ERROR' } } else { Write-Log " - (없음)" 'ERROR' }
} else { Write-Log " - (없음)" 'ERROR' }

Write-Log "User PATH 최근 항목(요약):" 'INFO'
$pathItems = [Environment]::GetEnvironmentVariable('Path','User')
if ($pathItems) {
    $items = $pathItems.Split(';') | Where-Object { $_ -ne '' }
    if ($items.Count -ge 5) { $items[-5..-1] | ForEach-Object { Write-Log " - $_" 'INFO' } }
    else { $items | ForEach-Object { Write-Log " - $_" 'INFO' } }
}

# userdata 기반 자동 로그인 로직은 보안 및 단순화 목적상 제거되었습니다.
# 필요한 경우 `scripts\login-from-userdata.ps1`를 수동으로 실행하여
# 브라우저 기반 `gh auth login --web` 흐름을 시작하세요.
