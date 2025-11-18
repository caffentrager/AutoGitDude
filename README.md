# AutoGitDude - 환경 설정 도우미

간단한 Windows 환경 부트스트랩 스크립트 모음입니다. 이 저장소의 `setup-environment.ps1` 스크립트는 개발자 환경에서 자주 사용하는 도구를 설치하거나 경로를 정리합니다.

주요 변경점
- Chocolatey, Git, GitHub CLI(gh)에 대해 **설치 여부를 먼저 확인**하며, 이미 설치되어 있으면 설치를 건너뜁니다.
- `userdata.login` 기반 자동 로그인 로직은 제거되었습니다. 대신 브라우저 기반 인증(`gh auth login --web`)을 사용하세요.

빠른 시작
1. 저장소를 클론합니다.

```powershell
git clone https://github.com/caffentrager/AutoGitDude.git
Set-Location AutoGitDude
```

2. 관리자 권한 PowerShell에서 실행(권장) 또는 `run-setup.bat` 사용:

PowerShell에서 직접:
```powershell
.\setup-environment.ps1
```

배치 파일(ExecutionPolicy 우회용):
```powershell
.\run-setup.bat
```

설치 정책
- `setup-environment.ps1`는 다음 툴을 확인하고 필요 시만 설치합니다:
  - Chocolatey (`choco`) ? 없을 때만 설치
  - Git (`git`) ? choco를 통해 설치(없을 때만)
  - GitHub CLI (`gh`) ? choco를 통해 설치(없을 때만)

인증
- 자동 토큰 저장을 권장하지 않으며, `gh auth login --web`(브라우저)를 사용한 수동 인증을 권장합니다.

보안 및 주의
- `run-setup.bat`는 실행정책을 임시로 우회합니다. 신뢰된 환경에서만 사용하세요.
- 민감 정보(토큰 등)는 평문 파일에 저장하지 마세요.

문제 발생 시
- 오류가 발생하면 스크립트 출력을 확인하고, 필요한 경우 관리자 권한으로 PowerShell을 실행해 주세요.

기여
- 간단한 개선, 버그 리포트 환영합니다. PR이나 Issue를 열어주세요.

---
`AutoGitDude`는 개발자의 반복 작업을 줄이기 위한 개인용 도구입니다. 사용 전에 스크립트를 검토하시기 바랍니다.
