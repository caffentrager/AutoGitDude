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
---
생성일: 2025