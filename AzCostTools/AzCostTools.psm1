$Public = @( Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -Recurse )
$Private = @( Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -Recurse )

@($Public + $Private) | ForEach-Object {
    Try {
        . $_.FullName
    }
    Catch {
        Write-Error -Message "Failed to import function $($_.FullName): $_"
    }
}

if (-not (Get-Module PSparklines -ListAvailable)) {
    Write-Warning "Dependency module 'PSparklines' not installed. Sparklines will not be generated. To fix execute: Install-Module PSparkines -Scope CurrentUser"
}