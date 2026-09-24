Describe Import-AzCostExport {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    InModuleScope AzCostTools {

        BeforeAll {
            function Get-AzStorageAccount {}
            function Get-AzStorageBlob {}
            function Get-AzStorageBlobContent { param($Container, $Blob, $Destination, $Context, [switch]$Force) }
            function Get-AzConsumptionBudget {}
            function Get-Sparkline {}
            function Write-Sparkline {}

            Mock Test-AzStorageModule { $true }
            Mock Get-AzConsumptionBudget {}
            Mock Get-Sparkline
            Mock Write-SparkLine

            Mock Get-AzStorageAccount {
                [pscustomobject]@{ Context = 'FakeContext' }
            }

            Mock Get-AzStorageBlob {
                @(
                    [pscustomobject]@{ Name = 'costexports/20240101-20240131/run1/part_0_0001.csv' }
                )
            }

            $script:CsvContent = @'
SubscriptionId,SubscriptionName,ResourceId,ResourceGroup,Date,ConsumedService,ProductName,BillingCurrencyCode,MeterName,MeterCategory,MeterSubCategory,UnitOfMeasure,Quantity,CostInBillingCurrency
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,SomeSubscription,/subscriptions/xxxx/resourceGroups/rg1/providers/Microsoft.Compute/disks/disk1,rg1,2024-01-01,Microsoft.Compute,Premium SSD,EUR,P15 LRS Disk,Storage,Premium SSD Managed Disks,1/Month,0.25,10
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx,SomeSubscription,/subscriptions/xxxx/resourceGroups/rg1/providers/Microsoft.Compute/disks/disk2,rg1,2024-01-02,Microsoft.Compute,Premium SSD,EUR,P15 LRS Disk,Storage,Premium SSD Managed Disks,1/Month,0.25,20
'@

            Mock Get-AzStorageBlobContent {
                Set-Content -Path $Destination -Value $script:CsvContent
            }
        }

        It 'Downloads and aggregates the matching export blob(s) into a Subscription.Cost object' {
            # Act
            $Result = Import-AzCostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -BillingMonth '01/2024'

            # Assert
            $Result.PSObject.TypeNames[0] | Should -Be 'Subscription.Cost'
            $Result.Name | Should -Be 'SomeSubscription'
            $Result.BillingPeriod | Should -Be '202401'
            $Result.Cost | Should -Be 30
            $Result.DailyCost.Count | Should -Be 2

            Should -Invoke Get-AzStorageBlobContent -Times 1 -Exactly
        }

        It 'Includes the mapped raw consumption records when -Raw is specified' {
            # Act
            $Result = Import-AzCostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -BillingMonth '01/2024' -Raw

            # Assert
            $Result.Consumption_Raw.Count | Should -Be 2
        }

        It 'Ignores blobs whose folder date range does not match the requested billing month' {
            # Arrange
            Mock Get-AzStorageBlob {
                @(
                    [pscustomobject]@{ Name = 'costexports/20230101-20230131/run1/part_0_0001.csv' }
                )
            }

            # Act / Assert
            Import-AzCostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -BillingMonth '01/2024' -ErrorVariable ImportError -ErrorAction SilentlyContinue

            $ImportError | Should -Not -BeNullOrEmpty
            Should -Invoke Get-AzStorageBlobContent -Times 0 -Exactly
        }

        It 'Writes an error and does not proceed when the Az.Storage module is not installed' {
            # Arrange
            Mock Test-AzStorageModule { $false }

            # Act
            Import-AzCostExport -StorageAccountName 'mycostexports' -ResourceGroupName 'rg-cost' -ContainerName 'costexports' -ErrorAction SilentlyContinue -ErrorVariable ImportError

            # Assert
            $ImportError | Should -Not -BeNullOrEmpty
            Should -Invoke Get-AzStorageAccount -Times 0 -Exactly
        }
    }
}
