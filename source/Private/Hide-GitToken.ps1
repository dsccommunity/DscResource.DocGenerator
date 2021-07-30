<#
    .SYNOPSIS
        Hides token from Invoke-Git command.

    .DESCRIPTION
        Formats Invoke-Git command to be used in Write-Debug & Write-Verbose.
        Replaces token using regex replace.

    .PARAMETER Command
        Command passed to Invoke-Git

    .EXAMPLE
        Hide-GitToken -Command @( 'clone', 'https://github.com/Owner/Repo.git' )

        Returns a string to be used for Write-Verbose & Write-Debug
#>

function Hide-GitToken
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory=$true)]
        [System.String[]]
        $Command
    )

    [System.String] $returnValue = $Command -join ' '

    [System.String] $returnValue = $returnValue -replace "gh(p|o|u|s|r)_([A-Za-z0-9]{1,255})",'**REDACTED-TOKEN**'

    [System.String] $returnValue = $returnValue -replace "[0-9a-f]{40}",'**REDACTED-TOKEN**'

    return $returnValue
}
