<#
    .SYNOPSIS
        Shows return object from Invoke-Git.

    .DESCRIPTION
        When Invoke-Git returns a non-zero exit code, this function shows the result.

    .PARAMETER ExitCode
        ExitCode returned from running git command.

    .PARAMETER StandardOutput
        Standard Output returned from running git command.

    .PARAMETER StandardError
        Standard Error returned from running git command.

    .PARAMETER Command
        Command arguments passed to git.

    .PARAMETER WorkingDirectory
        Working Directory used when running git command.

    .EXAMPLE
        $splatParameters = @{
            'ExitCode'         = 128
            'StandardOutput'   = 'StandardOutput-128'
            'StandardError'    = 'StandardError-128'
            'Command'          = 'commit --message "some message"'
            'WorkingDirectory' = 'C:\some\path\'
        }

        Out-GitResult @splatParameters

        Shows the Invoke-Git result of a commit.

    .NOTES
        $NULL values are allowed since string formatter `-f` will convert it to an
        empty string before Write-Verbose/Write-Debug process `-Message`.
#>

function Out-GitResult
{
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $ExitCode,

        [Parameter()]
        [System.String]
        $StandardOutput,

        [Parameter()]
        [System.String]
        $StandardError,

        [Parameter(Mandatory = $true)]
        [System.String[]]
        $Command,

        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory
    )

    switch ($Command[0].ToUpper())
    {
        'CLONE'
                {
                    if ($ExitCode -eq 128)
                    {
                        Write-Verbose -Message $script:localizedData.WikiGitCloneFailMessage
                    }
                }
        'COMMIT'
                {
                    if ($ExitCode -eq 1)
                    {
                        Write-Verbose -Message $script:localizedData.NothingToCommitToWiki
                    }
                }
    }

    Write-Verbose -Message ($script:localizedData.InvokeGitStandardOutputMessage -f $StandardOutput)
    Write-Verbose -Message ($script:localizedData.InvokeGitStandardErrorMessage -f $StandardError)
    Write-Verbose -Message ($script:localizedData.InvokeGitExitCodeMessage -f $ExitCode)

    Write-Debug -Message ($script:localizedData.InvokeGitCommandDebug -f $(Hide-GitToken -Command $Command))
    Write-Debug -Message ($script:localizedData.InvokeGitWorkingDirectoryDebug -f $WorkingDirectory)
}
