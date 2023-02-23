winget -v
IF %ErrorLevel%==0 (
    winget install --id=Microsoft.PowerShell --source=winget
    ) ELSE (
    EXIT 1
    )
