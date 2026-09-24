# Import-CostExport

## SYNOPSIS
Loads Azure cost data from a Cost Management scheduled export held in a Storage Account.

## SYNTAX

```
Import-CostExport [-StorageAccountName] <String> [-ResourceGroupName] <String> [-ContainerName] <String>
 [[-Prefix] <String>] [[-BillingMonth] <DateTime>] [[-PreviousMonths] <Int32>] [[-SparkLineSize] <Int32>]
 [-Raw] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Azure Cost Management can be configured (in the Azure Portal, under Cost Management \> Exports) to routinely write
"Actual Cost" CSV exports to a Storage Account container.
Import-CostExport reads the export file/s for a given
billing month directly from that container, and aggregates them into the same object shape returned by
Get-SubscriptionCost, so the result can be piped to Show-CostAnalysis or Export-CostData like any other cost data
-- without needing to query the Consumption API at all.

## EXAMPLES

### EXAMPLE 1
```
Import-CostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports'
```

Description
-----------
Loads cost data for the current billing month from the specified Storage Account container.

### EXAMPLE 2
```
Import-CostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -BillingMonth 01/2024 -PreviousMonths 3
```

Description
-----------
Loads cost data from October 2023 to January 2024 from the specified Storage Account container.

## PARAMETERS

### -StorageAccountName
The name of the Storage Account the scheduled export writes to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResourceGroupName
The name of the Resource Group containing the Storage Account.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ContainerName
The name of the blob container the scheduled export writes to.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Prefix
An optional blob name prefix (e.g.
the export name) to scope the search, useful if the container holds more than one export.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BillingMonth
The billing month to load cost data for, specified as a \[datetime\] object.
You can specify just month/year, e.g 10/2023.
If not specified uses the current date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: Month

Required: False
Position: 5
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreviousMonths
The number of previous billing months to load.
Default: 0.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: PrevMonths

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SparkLineSize
The row height of sparklines to generate (requires PSparklines module).
Default: 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Switch: Include the mapped export rows as a property on the returned object.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{Fill ProgressAction Description}}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
