# 간단한 유닛 테스트(의존성 없음)
# 주요 함수: Normalize-PathString 동작 검증

function Assert-Equal {
    param($Name, $Expected, $Actual)
    if ($Expected -eq $Actual) { Write-Host "[PASS] $Name" -ForegroundColor Green } else { Write-Host "[FAIL] $Name - Expected: '$Expected' Actual: '$Actual'" -ForegroundColor Red; exit 1 }
}

# 동일 로직 복제: setup-environment.ps1의 Normalize-PathString 함수 테스트용 복제
function Normalize-PathString_TestCopy {
    param([string]$p)
    if (-not $p) { return $null }
    try {
        if (Test-Path -LiteralPath $p -PathType Any) {
            return (Get-Item -LiteralPath $p -ErrorAction Stop).FullName.TrimEnd('\','/')
        }
    } catch { }
    return $p.TrimEnd('\','/').ToLowerInvariant()
}

Write-Host "테스트 시작: Normalize-PathString" -ForegroundColor Cyan

# 1) 존재하는 경로 케이스
$temp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "agd_test_$(Get-Random)") -Force
try {
    $input = $temp.FullName + '\\'
    $actual = Normalize-PathString_TestCopy -p $input
    $expected = $temp.FullName.TrimEnd('\','/')
    Assert-Equal "존재하는 경로 정규화" $expected $actual
}
finally {
    Remove-Item -LiteralPath $temp.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

# 2) 존재하지 않는 경로 케이스
$non = 'C:\NonExistent_Path_For_Test\\'
$actual2 = Normalize-PathString_TestCopy -p $non
$expected2 = $non.TrimEnd('\','/').ToLowerInvariant()
Assert-Equal "비존재 경로 정규화" $expected2 $actual2

Write-Host "모든 테스트 통과" -ForegroundColor Cyan
exit 0
