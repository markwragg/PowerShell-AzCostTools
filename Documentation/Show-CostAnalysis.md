# Show-CostAnalysis

## SYNOPSIS
Performs analysis of the data returned by Get-SubscriptionCost and generates charts and statistics.

## SYNTAX

```
Show-CostAnalysis [[-Cost] <Object>] [[-ConvertToCurrency] <String>] [[-SparkLineSize] <Int32>]
 [<CommonParameters>]
```

## DESCRIPTION
Use with Get-SubscriptionCost to generate charts and statistics for Azure consumption data.
Useful for
getting a quick view of the historical costs of one of more Azure subscriptions across one or more months
and to see the current Total costs, cost by day (as a chart), Top 15 most expensive service types, etc.

## EXAMPLES

### EXAMPLE 1
```
Get-SubscriptionCost | Show-CostAnalysis
```

Description
-----------
Returns cost analysis information for the current billing month for all subscriptions in the current Azure context.

### EXAMPLE 2
```
Show-CostAnalysis -Cost $Cost -SparkLineSize 5
```

Description
-----------
Returns cost analysis information for the cost data in $Cost with Sparkline charts that are 5 rows in height.

## PARAMETERS

### -Cost
The cost object returned by Get-SubscriptionCost

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ConvertToCurrency
Specify via 3 letter code, a currency that you would like the subscription costs converted to.
E.g: USD, GBP, EUR, CAD

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SparkLineSize
The row height of sparklines to generate (requires PSparkines module).
Default: 3.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 3
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
