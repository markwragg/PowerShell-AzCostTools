# Get-CostAdvisor

## SYNOPSIS
Retrieves Azure cost advisor recommendations for one or more subscriptions.

## SYNTAX

```
Get-CostAdvisor [[-SubscriptionName] <String[]>] [[-Impact] <String[]>] [-Raw] [<CommonParameters>]
```

## DESCRIPTION
Invokes the Get-AzAdvisorRecommendation cmdlet against one or more subscriptions and returns recommendations categorised as "Cost".

## EXAMPLES

### EXAMPLE 1
```
Get-CostAdvisor
```

Description
-----------
Returns the current cost advisor recommendations for all subscriptions in the current Azure context.

### EXAMPLE 2
```
Get-CostAdvisor -SubscriptionName 'MySubscriptionA','MySubscriptionB'
```

Description
-----------
Returns the current cost advisor recommendations for the specified subscription names.

### EXAMPLE 3
```
Get-CostAdvisor -Impact Medium,High
```

Description
-----------
Returns the current cost advisor recommendations that match the specified impact levels.

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

### -Impact
Use to filter the results to one or more impact categories: High, Medium or Low.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Raw
Switch: Include the raw advisor recommendation data as a property on the returned object.

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
