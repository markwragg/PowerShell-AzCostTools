# Get-SubscriptionCost

## SYNOPSIS
Retrieves the Azure costs for one or more billing months for one or more subscriptions.

## SYNTAX

```
Get-SubscriptionCost [[-SubscriptionName] <String[]>] [[-BillingMonth] <DateTime>] [[-PreviousMonths] <Int32>]
 [[-SparkLineSize] <Int32>] [-ComparePrevious] [-Raw] [<CommonParameters>]
```

## DESCRIPTION
Invokes the Get-AzConsumptionUsageDetail cmdlet against one or more subscriptions to return billing data for a specified number of months.
If you are interested to see how costs have changed since the previous mont use the -ComparePrevious switch to return additional properties
that contain the cost data for the previous month and properties that calculate the cost difference.

## EXAMPLES

### EXAMPLE 1
```
Get-SubscriptionCost
```

Description
-----------
Returns costs for the current billing month for all subscriptions in the current Azure context.

### EXAMPLE 2
```
Get-SubscriptionCost -SubscriptionName 'MySubscriptionA'
```

Description
-----------
Returns costs for the current billing month for the specified subscription name.

### EXAMPLE 3
```
Get-SubscriptionCost -SubscriptionName 'MySubscriptionA','MySubscriptionB'
```

Description
-----------
Returns costs for the current billing month for the specified subscription names.

### EXAMPLE 4
```
Get-SubscriptionCost -BillingMonth 01/2024 -PreviousMonths 3
```

Description
-----------
Returns costs from October 2023 to January 2024 for all subscriptions in the current Azure context.

### EXAMPLE 5
```
Get-SubscriptionCost -BillingMonth 01/2024 -PreviousMonths 3 -ComparePrevious
```

Description
-----------
Returns costs from October 2023 to January 2024 for all subscriptions in the current Azure context and includes properties
for comparing each month with the one prior.

## PARAMETERS

### -SubscriptionName
The name or name/s of the Subscriptions to query.
If not specified all subscriptions available in the current context will be used.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BillingMonth
The billing month to query for cost data, specified as a \[datetime\] object.
You can specify just month/year, e.g 10/2023.
If not specified uses the current date.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: (Get-Date)
Accept pipeline input: False
Accept wildcard characters: False
```

### -PreviousMonths
The number of previous billing months to query.
Default: 0.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -SparkLineSize
The row height of sparklines to generate (requires PSparkines module).
Default: 1.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComparePrevious
Switch: Include values for the previous billing month and adds additional properties that compare the current month to the previous.

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

### -Raw
Switch: Include the raw cost consumption data as a property on the returned object.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS