function Get-EaAccessToken {
    <#
    .SYNOPSIS
        Returns an access token for the current Az context, for use against the Azure Resource Manager REST API.
    #>
    [CmdletBinding()]
    param ()

    $resource = 'https://management.azure.com'
    $context = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile.DefaultContext
    [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
}
