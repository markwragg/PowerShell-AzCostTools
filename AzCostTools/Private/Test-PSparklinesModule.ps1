function Test-PSparklinesModule {
    <#
    .SYNOPSIS
        Returns true if the PSparklines module is installed.
    #>
    if (Get-Module PSparklines -ListAvailable) {
        $true
    }
    else {
        $false
    }
}