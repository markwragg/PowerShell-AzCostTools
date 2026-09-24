# Import-CostData

## SYNOPSIS
Loads cost data previously saved with Export-CostData.

## SYNTAX

```
Import-CostData [-Path] <String> [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Reloads cost data that was saved to disk with Export-CostData.
The returned objects are equivalent to the
original output of Get-SubscriptionCost/Get-StorageCost/Get-CostAdvisor and can be piped directly to Show-CostAnalysis
or Export-CostData again.

## EXAMPLES

### EXAMPLE 1
```
Import-CostData -Path C:\Cost\SubscriptionCost.json | Show-CostAnalysis
```

Description
-----------
Loads previously saved cost data and pipes it to Show-CostAnalysis.

### EXAMPLE 2
```
Import-CostData -Path C:\Cost
```

Description
-----------
Loads and returns cost data from every JSON file within the specified directory.

## PARAMETERS

### -Path
The JSON file previously created by Export-CostData.
If a directory is specified instead, every *.json file within it is imported.

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
