try {
    [System.Management.Automation.Language.Parser]::ParseFile('g:\project\AutoGitDude\scripts\setup-msys.ps1',[ref]$null,[ref]$null)
    Write-Host 'PARSE_OK'
}
catch {
    Write-Host 'PARSE_ERROR_FULL:'
    Write-Host $_.Exception.ToString()
    exit 1
}
