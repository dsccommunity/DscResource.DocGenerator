<#
    .SYNOPSIS
        Invokes a git command.

    .DESCRIPTION
        Invokes a git command with command line arguments using System.Diagnostics.Process.

    .PARAMETER WorkingDirectory
        The path to the git working directory.

    .PARAMETER Timeout
        Milliseconds to wait for process to exit.

    .PARAMETER Arguments
        The arguments to pass to the Git executable.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'clone', 'https://github.com/X-Guardian/xActiveDirectory.wiki.git', '--quiet' )

        Invokes the Git executable to clone the specified repository to the working directory.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'status' ) -TimeOut 10000

        Invokes the Git executable to return the status while having a 10000 millisecond timeout.
#>

function Invoke-Git
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $WorkingDirectory,

        [Parameter(Mandatory = $false)]
        [System.Int32]
        $TimeOut = 120000,

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

    $gitResult = @{
        'ExitCode'         = -1
        'StandardOutput'   = ''
        'StandardError'    = ''
        'Command'          = $argumentsJoined
        'WorkingDirectory' = $WorkingDirectory
    }

    try
    {
        $process = New-Object -TypeName System.Diagnostics.Process
        $process.StartInfo.Arguments = $Arguments
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.FileName = 'git'
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $process.StartInfo.WorkingDirectory = $WorkingDirectory

        if ($process.Start() -eq $true)
        {
            if ($process.WaitForExit($TimeOut) -eq $true)
            {
                $gitResult.ExitCode = $process.ExitCode
                $gitResult.StandardOutput = $process.StandardOutput.ReadToEnd()
                $gitResult.StandardError = $process.StandardError.ReadToEnd()

                # Remove all new lines at end of string.
                $gitResult.StandardOutput = $gitResult.StandardOutput -replace '[\r?\n]+$'
                $gitResult.StandardError = $gitResult.StandardError -replace '[\r?\n]+$'

                if ($gitResult.StandardOutput -match ':[\d|a-f].*@')
                {
                    $gitResult.StandardOutput = $gitResult.StandardOutput -replace ':[\d|a-f].*@', ':RedactedToken@'
                }

                if ($gitResult.StandardError -match ':[\d|a-f].*@')
                {
                    $gitResult.StandardError = $gitResult.StandardError -replace ':[\d|a-f].*@', ':RedactedToken@'
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
            $process.Dispose()
        }

        if ($VerbosePreference -ne 'SilentlyContinue' -or `
            $DebugPreference -ne 'SilentlyContinue' -or `
            $PSBoundParameters['Verbose'] -eq $true -or `
            $PSBoundParameters['Debug'] -eq $true)
        {
            Show-InvokeGitReturn @gitResult
        }
    }

    return $gitResult
}
