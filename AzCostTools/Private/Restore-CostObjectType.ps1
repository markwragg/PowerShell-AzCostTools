function Restore-CostObjectType {
    <#
    .SYNOPSIS
        Restores the PSTypeName and [datetime] typing of a cost object that has been round-tripped through ConvertTo-Json/ConvertFrom-Json.

    .DESCRIPTION
        Used by Import-CostData. JSON serialization drops the PSTypeName (it isn't a real property) and turns [datetime]
        properties into strings (or, under Windows PowerShell, into an object with a '/Date(<ms>)/' value), which breaks
        Show-CostAnalysis (it calls .Date.ToShortDateString() directly) and the module's *.Format.ps1xml views (which are
        selected by type name). This function recursively walks the object graph (including nested arrays such as
        DailyCost/CostPerService/DailyCostChange/ActiveBudgets), casts any property whose name ends in 'Date' back to
        [datetime], and re-stamps the supplied type name.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $InputObject,

        [Parameter(Mandatory)]
        [string]
        $TypeName
    )

    function Restore-DateProperty ($Object) {

        foreach ($Property in @($Object.PSObject.Properties)) {

            if ($Property.Value -is [string] -and $Property.Name -like '*Date') {
                $Property.Value = [datetime]$Property.Value
            }
            elseif ($Property.Name -like '*Date' -and $Property.Value -is [System.Management.Automation.PSCustomObject] -and $Property.Value.PSObject.Properties.Name -contains 'value') {
                # Windows PowerShell's ConvertTo-Json serializes [datetime] as an object carrying a '/Date(<ms-since-epoch>)/' value instead of an ISO string.
                # ConvertFrom-Json usually auto-converts that 'value' member back to a [datetime] itself; fall back to parsing it if it's still the raw string form.
                $RawValue = $Property.Value.value
                if ($RawValue -is [datetime]) {
                    $Property.Value = $RawValue.ToLocalTime()
                }
                elseif ($RawValue -is [string] -and $RawValue -match '^/Date\((\d+)\)/$') {
                    $Property.Value = [datetimeoffset]::FromUnixTimeMilliseconds([long]$Matches[1]).LocalDateTime
                }
            }
            elseif ($Property.Value -is [array]) {
                foreach ($Item in $Property.Value) {
                    if ($Item -is [System.Management.Automation.PSCustomObject]) {
                        Restore-DateProperty -Object $Item
                    }
                }
            }
            elseif ($Property.Value -is [System.Management.Automation.PSCustomObject]) {
                Restore-DateProperty -Object $Property.Value
            }
        }
    }

    Restore-DateProperty -Object $InputObject

    $InputObject.PSObject.TypeNames.Insert(0, $TypeName)

    $InputObject
}
