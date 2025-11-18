$entries = [Environment]::GetEnvironmentVariable('Path','User') -split ';' | Where-Object { $_ -and $_ -like '*mingw*' }
if ($entries) { $entries | ForEach-Object { Write-Host "USER_PATH_ENTRY: $_" } } else { Write-Host 'USER_PATH_ENTRY: (none)' }
