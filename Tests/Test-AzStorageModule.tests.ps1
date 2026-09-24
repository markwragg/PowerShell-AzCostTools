Describe Test-AzStorageModule {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Test-AzStorageModule.ps1
    }

    It 'Should return false if the module is not installed' {

        Mock Get-Module -ParameterFilter { $Name -eq 'Az.Storage' } {}

        Test-AzStorageModule | Should -Be $false
    }

    It 'Should return true if the module is installed' {

        Mock Get-Module -ParameterFilter { $Name -eq 'Az.Storage' } {
            [pscustomobject]@{
                Name = 'Az.Storage'
            }
        }

        Test-AzStorageModule | Should -Be $true
    }
}
