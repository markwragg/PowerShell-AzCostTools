# Set-SubscriptionBudget

## SYNOPSIS
Updates the amount of one or more Azure subscription budgets based on recent actual spend.

## SYNTAX

```
Set-SubscriptionBudget [[-SubscriptionName] <String[]>] [[-BudgetName] <String>] [[-BillingMonth] <DateTime>]
 [[-Months] <Int32>] [[-BufferPercent] <Double>] [[-MinimumAmount] <Double>] [-CreateIfMissing]
 [[-TimeGrain] <String>] [-PassThru] [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Calculates the average cost for a number of previous billing months (via Get-SubscriptionCost) and updates
the amount of the subscription's existing consumption budget to match, optionally adding a percentage buffer.
This allows a budget to be kept in step with genuinely changing costs, rather than remaining a fixed figure
that is manually maintained.

By default the first budget found for the subscription is updated.
Use -BudgetName if a subscription has
multiple budgets and you want to target a specific one.
If no budget exists and -CreateIfMissing is
specified, a new monthly budget is created instead.

## EXAMPLES

### EXAMPLE 1
```
Set-SubscriptionBudget
```

Description
-----------
Updates the budget for every subscription in the current Azure context to match its average spend over the previous 3 billing months.

### EXAMPLE 2
```
Set-SubscriptionBudget -SubscriptionName 'MySubscriptionA' -Months 6 -BufferPercent 10 -WhatIf
```

Description
-----------
Shows what the budget for 'MySubscriptionA' would be updated to, based on its average spend over the previous 6 billing months plus a 10% buffer, without making any change.

### EXAMPLE 3
```
Set-SubscriptionBudget -SubscriptionName 'MySubscriptionA' -Months 1 -PassThru
```

Description
-----------
Updates the budget for 'MySubscriptionA' to match its spend for the previous billing month alone, and returns an object describing the change.

### EXAMPLE 4
```
Set-SubscriptionBudget -SubscriptionName 'MySubscriptionA' -CreateIfMissing -BudgetName 'MySubscriptionA-Budget'
```

Description
-----------
Updates the existing budget named 'MySubscriptionA-Budget' for 'MySubscriptionA', or creates it (as a Monthly budget) if it does not already exist.

## PARAMETERS

### -SubscriptionName
The name or name/s of the Subscriptions to update the budget for.
If not specified all subscriptions available
in the current context will be used.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases: Name, Subscription

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BudgetName
The name of a specific budget to update (or create, when used with -CreateIfMissing).
If not specified, the
first budget found for the subscription is used.

```yaml
Type: String
Parameter Sets: (All)
Aliases: Budget

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BillingMonth
The most recent billing month to include in the spend average, specified as a \[datetime\] object.
Defaults to
the previous calendar month, since the current month's spend is typically incomplete.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases: Month

Required: False
Position: 3
Default value: (Get-Date).AddMonths(-1)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Months
The number of billing months (ending with -BillingMonth) to average when calculating the new budget amount.
Default: 3.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: PrevMonths

Required: False
Position: 4
Default value: 3
Accept pipeline input: False
Accept wildcard characters: False
```

### -BufferPercent
A percentage to add on top of the calculated average spend, e.g.
specify 10 to set the budget 10% higher than
average spend.
Can be negative to set the budget below average spend.
Default: 0.

```yaml
Type: Double
Parameter Sets: (All)
Aliases: Buffer

Required: False
Position: 5
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -MinimumAmount
If specified, the new budget amount will never be set lower than this value, regardless of the calculated
average spend.

```yaml
Type: Double
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreateIfMissing
Switch: If no existing budget is found for a subscription, create a new one using -BudgetName (or a generated
name if not specified) and -TimeGrain, instead of skipping that subscription.

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

### -TimeGrain
The time grain to use when creating a new budget with -CreateIfMissing.
Default: Monthly.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 7
Default value: Monthly
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassThru
Switch: Return an object describing the budget change made (or that would be made, with -WhatIf) for each subscription.

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

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
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
