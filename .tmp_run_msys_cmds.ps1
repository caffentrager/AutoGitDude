$bash = 'C:\tools\msys64\msys64\usr\bin\bash.exe'
if (Test-Path $bash) {
    Write-Host "Found bash: $bash"
    & $bash -lc "pacman-key --init; pacman-key --populate msys2; yes | pacman -Syu --noconfirm; yes | pacman -S --noconfirm msys2-runtime base-devel mingw-w64-x86_64-toolchain"
} else {
    Write-Host "bash.exe not found at $bash"
}
