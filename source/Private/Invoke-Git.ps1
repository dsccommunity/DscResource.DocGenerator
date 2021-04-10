<#
    .SYNOPSIS
        Invokes the git command.

    .PARAMETER Arguments
        The arguments to pass to the Git executable.

    .EXAMPLE
        Invoke-Git clone https://github.com/X-Guardian/xActiveDirectory.wiki.git --quiet

        Invokes the Git executable to clone the specified repository to the current working directory.
#>

function Invoke-Git
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromRemainingArguments = $true)]
        [System.String[]]
        $Arguments
    )

    $argumentsJoined = $Arguments -join ' '

    # Trying to remove any access token from the debug output.
    if ($argumentsJoined -match ':[\d|a-f].*@')
    {
        $argumentsJoined = $argumentsJoined -replace ':[\d|a-f].*@', ':RedactedToken@'
    }

    Write-Debug -Message ($localizedData.InvokingGitMessage -f $argumentsJoined)

    try
    {
        & git @Arguments

        <#
            Assuming the error code 1 from git is warnings or informational like
            "nothing to commit, working tree clean" and those are returned instead
            of throwing an exception.
        #>
        if ($LASTEXITCODE -gt 1)
        {
            throw $LASTEXITCODE
        }
    }
    catch
    {
        throw $_
    }

    return $LASTEXITCODE
}
