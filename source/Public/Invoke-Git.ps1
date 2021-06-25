<#
    .SYNOPSIS
        Invokes a git command.

    .DESCRIPTION
        Invokes a git command with command line arguments using System.Diagnostics.Process.

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
    [OutputType([System.Collections.Hashtable])]
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

    $returnValue = @{
        'ExitCode'       = -1
        'StandardOutput' = ''
        'StandardError'  = ''
    }

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
                $returnValue.ExitCode = $process.ExitCode
                $returnValue.StandardOutput = $process.StandardOutput.ReadToEnd()
                $returnValue.StandardError = $process.StandardError.ReadToEnd()
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
    }

    return $returnValue
}
