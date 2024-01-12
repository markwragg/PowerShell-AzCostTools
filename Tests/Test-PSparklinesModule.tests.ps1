Describe Test-PSparklinesModule {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Test-PSparklinesModule.ps1
    }

    It 'Should return false if the module is not installed' {

        Mock Get-Module -ParameterFilter { $Name -eq 'PSparklines' } {}

        Test-PSparklinesModule | Should -Be $false
    }

    It 'Should return true if the module is not installed' {

        Mock Get-Module -ParameterFilter { $Name -eq 'PSparklines' } {
            [pscustomobject]@{
                Name = 'PSparklines'
            }
        }

        Test-PSparklinesModule | Should -Be $true
    }
}