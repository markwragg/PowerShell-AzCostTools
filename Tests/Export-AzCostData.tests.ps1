Describe Export-AzCostData {

    Import-Module (Join-Path $PSScriptRoot "/../AzCostTools")

    Context 'When exporting cost data to a specific file' {

        It 'Writes a JSON file containing the type name and data for each object' {
            # Arrange
            $Cost = [pscustomobject]@{
                PSTypeName = 'Subscription.Cost'
                Name       = 'SomeSubscription'
                Cost       = 30
            }
            $Path = Join-Path $TestDrive 'cost.json'

            # Act
            $Cost | Export-AzCostData -Path $Path

            # Assert
            Test-Path $Path | Should -Be $true

            $Content = @(Get-Content $Path -Raw | ConvertFrom-Json)
            $Content.Count | Should -Be 1
            $Content[0].TypeName | Should -Be 'Subscription.Cost'
            $Content[0].Data.Name | Should -Be 'SomeSubscription'
            $Content[0].Data.Cost | Should -Be 30
        }
    }

    Context 'When Path is a directory' {

        It 'Creates a timestamped file within it' {
            # Arrange
            $Cost = [pscustomobject]@{ PSTypeName = 'Subscription.Cost'; Name = 'SomeSubscription'; Cost = 30 }
            $Directory = Join-Path $TestDrive 'DirectoryExport'
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null

            # Act
            $Cost | Export-AzCostData -Path $Directory

            # Assert
            @(Get-ChildItem -Path $Directory -Filter 'AzCostData_*.json').Count | Should -Be 1
        }
    }

    Context 'When exporting multiple objects via the pipeline' {

        It 'Writes an entry for each object' {
            # Arrange
            $Cost = @(
                [pscustomobject]@{ PSTypeName = 'Subscription.Cost'; Name = 'SubA'; Cost = 10 },
                [pscustomobject]@{ PSTypeName = 'Subscription.Cost'; Name = 'SubB'; Cost = 20 }
            )
            $Path = Join-Path $TestDrive 'multi.json'

            # Act
            $Cost | Export-AzCostData -Path $Path

            # Assert
            $Content = @(Get-Content $Path -Raw | ConvertFrom-Json)
            $Content.Count | Should -Be 2
        }
    }
}
