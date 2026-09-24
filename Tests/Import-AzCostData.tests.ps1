Describe Import-AzCostData {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    Context 'When importing a single file' {

        BeforeAll {
            $Directory = Join-Path $TestDrive 'SingleFile'
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
            $Path = Join-Path $Directory 'cost.json'

            [pscustomobject]@{
                PSTypeName         = 'Subscription.Cost'
                Name               = 'SomeSubscription'
                BillingPeriod      = '202401'
                Cost               = 30
                MostExpensive_Date = (Get-Date '2024-01-02')
                DailyCost          = @(
                    [pscustomobject]@{ Date = (Get-Date '2024-01-01'); Cost = 10 },
                    [pscustomobject]@{ Date = (Get-Date '2024-01-02'); Cost = 20 }
                )
            } | Export-AzCostData -Path $Path
        }

        It 'Restores the type name and Date typing' {
            # Act
            $Result = Import-AzCostData -Path $Path

            # Assert
            $Result.PSObject.TypeNames[0] | Should -Be 'Subscription.Cost'
            $Result.Name | Should -Be 'SomeSubscription'
            $Result.BillingPeriod | Should -Be '202401'
            $Result.Cost | Should -Be 30
            $Result.MostExpensive_Date | Should -BeOfType 'datetime'
            $Result.DailyCost[0].Date | Should -BeOfType 'datetime'
            $Result.DailyCost[0].Date.ToShortDateString() | Should -Be (Get-Date '2024-01-01').ToShortDateString()
        }
    }

    Context 'When importing a directory of files' {

        BeforeAll {
            $Directory = Join-Path $TestDrive 'MultiFile'
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null

            [pscustomobject]@{ PSTypeName = 'Subscription.Cost'; Name = 'SubA' } | Export-AzCostData -Path (Join-Path $Directory 'a.json')
            [pscustomobject]@{ PSTypeName = 'Subscription.Cost'; Name = 'SubB' } | Export-AzCostData -Path (Join-Path $Directory 'b.json')
        }

        It 'Imports and concatenates every JSON file in the directory' {
            # Act
            $Result = @(Import-AzCostData -Path $Directory)

            # Assert
            $Result.Count | Should -Be 2
            @($Result.Name | Sort-Object) | Should -Be @('SubA', 'SubB')
        }
    }
}
