Describe 'Get-ResourceGroupNameFromInstanceId' {

    BeforeAll {
        . $PSScriptRoot/../AzCostTools/Private/Get-ResourceGroupNameFromInstanceId.ps1
    }

    Context 'When given a valid InstanceId' {

        It 'Returns the resource group name' {
            $InstanceId = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/SomeResourceGroup/providers/Microsoft.Storage/storageAccounts/SomeAccount'

            Get-ResourceGroupNameFromInstanceId $InstanceId | Should -Be 'SomeResourceGroup'
        }
    }

    Context 'When the InstanceId has fewer than 5 path segments' {

        It 'Returns nothing' {
            $InstanceId = '/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'

            Get-ResourceGroupNameFromInstanceId $InstanceId | Should -BeNullOrEmpty
        }
    }

    Context 'When the InstanceId is empty' {

        It 'Returns nothing' {
            Get-ResourceGroupNameFromInstanceId $null | Should -BeNullOrEmpty
        }
    }
}
