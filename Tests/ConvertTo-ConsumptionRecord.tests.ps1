Describe 'ConvertTo-ConsumptionRecord' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/ConvertTo-ConsumptionRecord.ps1
    }

    Context 'When given a row using the standard Actual Cost export column names' {

        It 'Maps the row to a Consumption-shaped record' {
            # Arrange
            $Row = [pscustomobject]@{
                SubscriptionId         = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                SubscriptionName       = 'SomeSubscription'
                ResourceId              = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg1/providers/Microsoft.Compute/disks/disk1'
                ResourceGroup           = 'rg1'
                Date                    = '2024-01-02'
                ConsumedService         = 'Microsoft.Compute'
                ProductName             = 'Premium SSD Managed Disks - P15 LRS - EU West'
                BillingCurrencyCode     = 'EUR'
                MeterName               = 'P15 LRS Disk'
                MeterCategory           = 'Storage'
                MeterSubCategory        = 'Premium SSD Managed Disks'
                UnitOfMeasure           = '1/Month'
                Quantity                = '0.25'
                CostInBillingCurrency   = '12.5'
            }

            # Act
            $Result = ConvertTo-ConsumptionRecord -Row $Row

            # Assert
            $Result.SubscriptionGuid | Should -Be 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
            $Result.SubscriptionName | Should -Be 'SomeSubscription'
            $Result.InstanceName | Should -Be $Row.ResourceId
            $Result.ResourceGroupName | Should -Be 'rg1'
            $Result.UsageStart | Should -Be (Get-Date '2024-01-02')
            $Result.ConsumedService | Should -Be 'Microsoft.Compute'
            $Result.Product | Should -Be 'Premium SSD Managed Disks - P15 LRS - EU West'
            $Result.Currency | Should -Be 'EUR'
            $Result.MeterDetails.MeterName | Should -Be 'P15 LRS Disk'
            $Result.MeterDetails.MeterCategory | Should -Be 'Storage'
            $Result.MeterDetails.MeterSubCategory | Should -Be 'Premium SSD Managed Disks'
            $Result.MeterDetails.Unit | Should -Be '1/Month'
            $Result.UsageQuantity | Should -Be 0.25
            $Result.PreTaxCost | Should -Be 12.5
        }
    }

    Context 'When given a row using fallback column names' {

        It 'Maps the row using the alternative column names' {
            # Arrange
            $Row = [pscustomobject]@{
                SubscriptionId   = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
                SubscriptionName = 'SomeSubscription'
                UsageDateTime    = '2024-01-03'
                ConsumedService  = 'Microsoft.Storage'
                Product          = 'Blob Storage'
                Currency         = 'GBP'
                Cost             = '3.75'
                UsageQuantity    = '10'
            }

            # Act
            $Result = ConvertTo-ConsumptionRecord -Row $Row

            # Assert
            $Result.UsageStart | Should -Be (Get-Date '2024-01-03')
            $Result.Product | Should -Be 'Blob Storage'
            $Result.Currency | Should -Be 'GBP'
            $Result.PreTaxCost | Should -Be 3.75
            $Result.UsageQuantity | Should -Be 10
        }
    }

    Context 'When cost/quantity columns are missing' {

        It 'Defaults PreTaxCost and UsageQuantity to 0' {
            # Arrange
            $Row = [pscustomobject]@{
                SubscriptionName = 'SomeSubscription'
                Date             = '2024-01-04'
                ConsumedService  = 'Microsoft.Compute'
            }

            # Act
            $Result = ConvertTo-ConsumptionRecord -Row $Row

            # Assert
            $Result.PreTaxCost | Should -Be 0
            $Result.UsageQuantity | Should -Be 0
        }
    }
}
