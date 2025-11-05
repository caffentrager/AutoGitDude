function Write-Log { param([string]$Message, [string]$Level = 'INFO')
    switch ($Level.ToUpper()) {
        'INFO' { Write-Host $Message -ForegroundColor Cyan }
        'WARN' { Write-Host $Message -ForegroundColor Yellow }
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        default { Write-Host $Message }
    }
}

# 경로 문자열 정규화: 존재하면 FullName 반환, 아니면 소문자-후행구분자 제거 형태로 반환
function Normalize-PathString {
    param([string]$p)
    if (-not $p) { return $null }
    try {
        if (Test-Path -LiteralPath $p -PathType Any) {
            return (Get-Item -LiteralPath $p -ErrorAction Stop).FullName.TrimEnd('\','/')
        }
    } catch { }
    # 존재하지 않아도 비교할 때는 소문자 및 후행 구분자 제거
    return $p.TrimEnd('\','/').ToLowerInvariant()
}
