function Test-AzStorageModule {
    <#
    .SYNOPSIS
        Returns true if the Az.Storage module is installed.
    #>
    if (Get-Module Az.Storage -ListAvailable) {
        $true
    }
    else {
        $false
    }
}
