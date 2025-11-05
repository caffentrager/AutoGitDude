# AutoGitDude

AutoGitDude는 로컬에서 빠르게 Git 저장소를 초기화하고 GitHub에 등록하기 위한 시작점입니다.

이 저장소에는 프로젝트 시작에 도움이 되는 기본 파일과, Windows 환경에서 개발 도구(Chocolatey, Git, GitHub CLI, MSYS2)를 자동으로 설치하고
사용자 범위의 PATH에 필요한 항목을 추가하는 PowerShell 스크립트(`setup-environment.ps1`)가 포함되어 있습니다.

## 포함된 파일

- `README.md` ? 이 파일
- `LICENSE` ? MIT 라이선스(저작권자 자리표시자)
- `.gitignore` ? 일반적인 항목
- `AutoGitDude.ps1` ? 샘플 PowerShell 스크립트
- `setup-environment.ps1` ? 개발환경 설치/설정 스크립트 (Windows)

## 빠른 시작

1. 저장소를 클론하거나 로컬에서 작업을 이어갑니다.
2. (선택) `setup-environment.ps1`로 개발 도구 설치 및 PATH 설정을 자동으로 시도할 수 있습니다. 아래 "환경 설정 스크립트" 섹션을 참고하세요.

## 환경 설정 스크립트: `setup-environment.ps1`

이 스크립트는 다음 작업을 시도합니다:

- Chocolatey 설치(미설치시) ? 관리자 권한이 필요할 수 있음
- `choco`로 `git`, `gh`(GitHub CLI), `msys2` 설치
- 설치된 도구의 실행 파일(예: msys2의 `usr\bin`, Git의 `cmd`)을 사용자(User) 범위의 PATH에 추가

중요 사항:

- 스크립트는 기본적으로 사용자 범위의 PATH를 수정하므로 관리자 권한 없이 실행할 수 있습니다. 다만 Chocolatey 또는 일부 패키지(msys2 등)는 관리자 권한으로 설치해야 할 수 있습니다.
- 설치 실패 시 관리자 권한으로 직접 설치한 뒤 스크립트를 다시 실행하세요.

실행 방법(PowerShell에서):

```powershell
Set-Location 'G:\project\AutoGitDude'
# 권장: 관리자 권한 불필요(사용자 PATH 적용) ? 다만 일부 설치는 관리자 권한 필요
.\setup-environment.ps1
```

GitHub CLI 로그인(gh 사용을 원하면):

```powershell
# 설치 후
gh auth login --hostname github.com --web
```

스크립트 동작 요약:

- 스크립트는 설치 시도를 수행하고, 설치된 도구를 찾으면 사용자 PATH에 추가합니다.
- 변경된 PATH는 새 셸에서 반영됩니다(로그아웃/로그인 또는 새 PowerShell 창).

## 다음 단계(권장)

- `setup-environment.ps1` 실행 후 `gh auth login`으로 GitHub에 로그인하세요.
- README에 사용법을 더 추가하거나 CI(예: GitHub Actions) 템플릿을 넣고 싶으면 요청하세요.

## 라이선스

MIT License ? `LICENSE` 파일을 참고하세요. `[Your Name]`을 실제 저작권자로 바꿔주세요.

---
생성일: 2025

## 인코딩(글꼴 깨짐) 문제 해결 안내

Windows 환경에서 에디터나 터미널에서 README가 한글로 깨져 보일 때는 파일 인코딩이 문제인 경우가 많습니다. 이 리포지터리는 UTF-8(BOM) 인코딩을 권장합니다.

다음 PowerShell 명령으로 현재 `README.md`를 UTF-8(BOM)으로 변환할 수 있습니다 (PowerShell 5.1/Windows PowerShell에서 동작합니다):

```powershell
# 현재 디렉터리에서 실행
$text = Get-Content -Raw -Path .\README.md
[System.IO.File]::WriteAllText((Resolve-Path .\README.md).Path, $text, New-Object System.Text.UTF8Encoding $true)
```

변환 후에는 편집기(또는 터미널)를 다시 열면 한글 글꼴 깨짐 현상이 해결되는지 확인하세요.

또 다른 방법: Visual Studio Code 등에서 파일 우측 하단의 인코딩 표시를 클릭하여 "UTF-8 with BOM"으로 재저장하면 됩니다.

---

필요하시면 제가 저장소의 `README.md`를 바로 UTF-8(BOM)으로 변환하고 커밋해 드릴게요.
---
생성일: 2025