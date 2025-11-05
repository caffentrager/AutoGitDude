# AutoGitDude — Setup & Environment

이 README는 오직 `setup-environment.ps1` 스크립트의 설치/실행 가이드만을 포함합니다.

## 목적

`setup-environment.ps1`은 Windows 환경에서 개발 도구(Chocolatey, Git, GitHub CLI(gh), MSYS2)를 자동으로 설치하고
필요한 실행 경로를 사용자(User) 범위의 PATH에 추가하는 보조 스크립트입니다.

## 사전 준비

- 인터넷 연결
- PowerShell(권장: Windows PowerShell 5.1 이상)
- Chocolatey 설치가 필요한 경우 관리자 권한이 요구될 수 있습니다(스크립트는 비관리자 시도 후 실패 시 안내함).

## 빠른 실행(권장)

1. PowerShell을 열고 리포지터리 루트로 이동:

```powershell
Set-Location 'G:\project\AutoGitDude'
```

2. 스크립트 실행:

```powershell
.\setup-environment.ps1
```

3. (선택) GitHub CLI 사용을 원하면 로그인:

```powershell
gh auth login --hostname github.com --web
```

## 스크립트 동작 요약

- Chocolatey가 없으면 설치 시도(관리자 권한 필요할 수 있음).
- `choco`로 `git`, `gh`, `msys2`를 설치(옵션으로 제어 가능).
- 설치된 도구의 실행 경로(예: `C:\msys64\usr\bin`, `C:\Program Files\Git\cmd`)를 사용자 PATH에 추가.
- 실행 후 추가된 경로/스킵된 경로/실패한 경로 요약을 출력.

## 권장 사항 및 주의

- Chocolatey 및 일부 패키지 설치는 관리자 권한이 필요합니다. 설치 실패 시 관리자 권한으로 다시 실행하세요.
- PATH 변경은 현재 세션에는 반영되지 않습니다. 새 PowerShell 창을 열거나 로그아웃/로그인하여 반영하세요.
- 필요 시 `README.md`는 UTF-8(BOM)으로 저장하면 한글 표시 문제를 줄일 수 있습니다.

## 문제 발생 시

- 실행 로그(터미널 출력)를 복사해서 알려주시면 진단을 도와드리겠습니다.
- 추가적으로 설치 로그 파일 저장 기능이나 더 많은 경로 후보 추가를 원하면 요청하세요.

---

생성일: 2025
---
생성일: 2025