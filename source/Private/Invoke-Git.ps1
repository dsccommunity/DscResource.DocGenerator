<#
    .SYNOPSIS
        Invokes a git command.

    .DESCRIPTION
        Invokes a git command with command line arguments.

    .PARAMETER WorkingDirectory
        The path to the git working directory.

    .PARAMETER Timeout
        Seconds to wait for process to exit.

    .PARAMETER Arguments
        The arguments to pass to the Git executable.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'clone', 'https://github.com/X-Guardian/xActiveDirectory.wiki.git', '--quiet' )

        Invokes the Git executable to clone the specified repository to the working directory.

    .EXAMPLE

        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'status' ) -TimeOut 10

        Invokes the Git executable to return the status while having a 10 second timeout.
#>

function Invoke-Git
{
    [CmdletBinding()]
    [OutputType([System.Int32])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $TimeOut = 120,

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
        $process = New-Object -TypeName System.Diagnostics.Process
        $process.StartInfo.Arguments = $Arguments
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.FileName = 'git.exe'
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $process.StartInfo.WorkingDirectory = $WorkingDirectory

        if ($process.Start() -eq $true)
        {
            if ($process.WaitForExit($TimeOut) -eq $true)
            {
                <#
                    Assuming the error code 1 from git is warnings or informational like
                    "nothing to commit, working tree clean" and those are returned instead
                    of throwing an exception.
                #>
                if ($process.ExitCode -gt 1)
                {
                    Write-Warning -Message ($localizedData.UnexpectedInvokeGitReturnCode -f $process.ExitCode)

                    Write-Debug -Message ($localizedData.InvokeGitStandardOutputReturn -f $process.StandardOutput.ReadToEnd())
                    Write-Debug -Message ($localizedData.InvokeGitStandardErrorReturn -f $process.StandardError.ReadToEnd())
                }
            }
        }
    }
    catch
    {
        throw $_
    }
    finally
    {
        if ($process)
        {
            $exitCode = $process.ExitCode
            $process.Dispose()
        }
    }

    return $exitCode
}
