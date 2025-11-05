# Pester 테스트: lib/common.ps1의 Normalize-PathString 검증
. "$PSScriptRoot\..\lib\common.ps1"

Describe 'Normalize-PathString 함수' {
    It '존재하는 경로는 FullName으로, 후행 슬래시 제거' {
        $temp = New-Item -ItemType Directory -Path (Join-Path $env:TEMP "agd_test_$(Get-Random)") -Force
        try {
            $inp = $temp.FullName + '\\'
            $actual = Normalize-PathString $inp
            $expected = $temp.FullName.TrimEnd([char]'\',[char]'/')
            $actual | Should Be $expected
        }
        finally {
            Remove-Item -LiteralPath $temp.FullName -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    It '비존재 경로는 소문자-후행구분자 제거 형태로 반환' {
    $non = 'C:\NonExistent_Path_For_Test\\'
    $actual = Normalize-PathString $non
    $expected = $non.TrimEnd([char]'\',[char]'/').ToLowerInvariant()
    $actual | Should Be $expected
    }
}
