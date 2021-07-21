<#
    .SYNOPSIS
        Hides token from Invoke-Git command.

    .DESCRIPTION
        Formats Invoke-Git command to be used in Write-Debug & Write-Verbose.
        Does not reveal token or other authentication methods.

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

    [System.String] $returnValue = $Command[0]

    if ([System.String]::IsNullOrWhiteSpace($Command[1]) -eq $false)
    {
        if ($Command[1].Length -gt 3)
        {
            $returnValue += " $($Command[1].Substring(0,3))..."
        }
        else
        {
            $returnValue += " $($Command[1])..."
        }
    }

    return $returnValue
}
