# AutoGitDude ? Setup & Environment

이 README는 오직 `setup-environment.ps1` 스크립트의 설치·실행 가이드를 제공합니다.

## 목적

`setup-environment.ps1`은 Windows 환경에서 개발을 시작할 때 반복되는 초기 작업을 자동화합니다:

- Chocolatey 설치(미설치 시)
- `choco`로 `git`, `gh`(GitHub CLI), `msys2` 설치
- 설치된 도구의 실행 경로를 사용자(User) 범위의 PATH에 추가

스크립트는 가능한 경우 비관리자(사용자) 범위에서 동작하도록 설계되었습니다. 다만 Chocolatey 및 일부 패키지는 관리자 권한이 필요할 수 있습니다.

---

## 빠른 시작

1) 리포지터리를 클론하거나 이미 클론한 디렉터리로 이동합니다.

```powershell
# 예: 자신의 경로로 바꿔서 사용하세요
Set-Location '<path-to-cloned-repo>'
# 또는 이미 루트라면 생략
```

2) 스크립트 실행

```powershell
.\setup-environment.ps1
```

3) (선택) GitHub CLI를 사용하려면 로그인:

```powershell
gh auth login --hostname github.com --web
```

---

## 스크립트 파라미터

스크립트에는 기본적으로 모든 항목을 설치하도록 설정되어 있습니다. 필요하다면 아래과 같은 옵션(예시)을 추가해 파라미터로 제어할 수 있습니다:

- `-InstallChocolatey:$false` ? Chocolatey 설치 건너뛰기
- `-InstallGit:$false` ? Git 설치 건너뛰기
- `-InstallGh:$false` ? GitHub CLI 설치 건너뛰기
- `-InstallMsys2:$false` ? MSYS2 설치 건너뛰기

예: `.\setup-environment.ps1 -InstallMsys2:$false`

---

## 스크립트가 수행하는 주요 작업 (요약)

- Chocolatey 설치(미설치 시, 관리자 권한 필요할 수 있음)
- `choco`로 `git`, `gh`, `msys2` 설치
- MSYS2, Git, gh의 실행 파일 경로를 사용자 PATH에 추가 (중복 방지 및 정규화 적용)
- 실행 결과로 Added/Skipped/Failed 목록을 출력

경로 후보 예:

- `C:\msys64`, `C:\msys64\usr\bin`
- `C:\tools\msys2\usr\bin`
- `$env:ChocolateyInstall\lib\msys2\tools\msys2\usr\bin`
- `C:\Program Files\Git\cmd`
- `%ProgramFiles%\GitHub CLI`

---

## 실행 후 검증

다음 명령으로 설치 및 PATH 적용 여부를 확인하세요:

```powershell
git --version
gh --version
where.exe bash

[Environment]::GetEnvironmentVariable('Path','User') -split ';' | Select-Object -Last 15
```

참고: PATH 변경은 새 PowerShell 창에서 반영됩니다. 현재 세션에서 바로 반영하려면 `refreshenv`가 있으면 사용하거나 새 창을 여세요.

---

## 문제 해결

- Chocolatey 설치 실패
  - 관리자 권한으로 설치를 시도하세요.
  - 수동 설치 명령(관리자 PowerShell):

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
iwr https://community.chocolatey.org/install.ps1 -UseBasicParsing | iex
```

- PATH 추가가 되지 않음
  - 스크립트가 출력한 `Added`/`Skipped`/`Failed` 목록을 확인하세요.
  - 수동으로 Windows 환경 변수 설정에서 편집 가능합니다.

- 한글/인코딩 깨짐
  - README는 UTF-8(BOM)으로 저장하는 것을 권장합니다. PowerShell로 변환하려면:

```powershell
$path=(Resolve-Path .\README.md).Path
$text=Get-Content -Raw -Path $path
$enc=New-Object System.Text.UTF8Encoding -ArgumentList $true
[System.IO.File]::WriteAllText($path,$text,$enc)
```

---

## 되돌리기(수동)

스크립트가 추가한 PATH를 제거하려면:

1. Windows 설정 > 시스템 > 환경 변수 > 사용자 변수에서 `Path`를 편집
2. 스크립트 실행 시 출력된 `Added` 목록에서 해당 항목을 삭제
3. 저장 후 새 세션 시작

원하시면 스크립트에 `--undo` 옵션을 추가해 자동으로 되돌리게 해드리겠습니다.

---

## 로깅(옵션)

설치 로그를 파일에 남기려면 스크립트 시작부에 간단한 로깅 기능을 추가 가능합니다. 요청하시면 적용해 드립니다.

---

생성일: 2025-11-05
