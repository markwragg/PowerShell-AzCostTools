# Export-CostData

## SYNOPSIS
Saves cost data returned by Get-SubscriptionCost, Get-StorageCost or Get-CostAdvisor to a JSON file for later reloading.

## SYNTAX

```
Export-CostData [-Cost] <Object> [-Path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Retrieving cost data from Azure can take a few minutes to run.
Export-CostData lets you persist the result to disk
so it can be reloaded later with Import-CostData for analysis or comparison, without needing to query Azure again.

## EXAMPLES

### EXAMPLE 1
```
Get-SubscriptionCost -ComparePrevious | Export-CostData -Path C:\Cost\SubscriptionCost.json
```

Description
-----------
Retrieves subscription cost data and saves it to the specified file.

### EXAMPLE 2
```
$Cost | Export-CostData -Path C:\Cost
```

Description
-----------
Saves the cost data held in $Cost to a timestamped file within the specified directory.

## PARAMETERS

### -Cost
The cost object/s returned by Get-SubscriptionCost, Get-StorageCost or Get-CostAdvisor.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Path
The file to save the cost data to.
If a directory is specified instead, a file named CostData_\<timestamp\>.json is created within it.

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
