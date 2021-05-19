<#
    .SYNOPSIS
        Invokes the git command.

    .PARAMETER Arguments
        The arguments to pass to the Git executable. First Argument MUST be the desired working directory.

    .EXAMPLE
        Invoke-Git D:\WorkingFolder clone https://github.com/X-Guardian/xActiveDirectory.wiki.git --quiet

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

    $workingDirectory = $Arguments[0]

    for ($i=1; $i -lt $Arguments.Length; $i++)
    {
        [string[]] $cmdArguments += $Arguments[$i]
    }

    $argumentsJoined = $cmdArguments -join ' '

    # Trying to remove any access token from the debug output.
    if ($argumentsJoined -match ':[\d|a-f].*@')
    {
        $argumentsJoined = $argumentsJoined -replace ':[\d|a-f].*@', ':RedactedToken@'
    }

    Write-Debug -Message ($localizedData.InvokingGitMessage -f $argumentsJoined)

    try
    {
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.Arguments = $cmdArguments
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.FileName = 'git.exe'
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        $process.StartInfo.WorkingDirectory = $workingDirectory

        if ($process.Start() -eq $true)
        {
            <#
                -1 specifies an infinite wait. Suitable for large commits,
                network issues, etc.
            #>
            if ($process.WaitForExit(-1) -eq $true)
            {
                <#
                    Assuming the error code 1 from git is warnings or informational like
                    "nothing to commit, working tree clean" and those are returned instead
                    of throwing an exception.
                #>
                if ($process.ExitCode -gt 1)
                {
                    Write-Warning -Message ($localizedData.UnexpectedInvokeGitReturnCode -f $process.ExitCode)
                    Write-Warning -Message "  PWD: $workingDirectory"
                    Write-Warning -Message "  git $argumentsJoined"

                    [string] $invokeGitOutput = $process.StandardOutput.ReadToEnd()
                    [string] $invokeGitError = $process.StandardError.ReadToEnd()

                    if ([System.String]::IsNullOrWhiteSpace($invokeGitOutput) -eq $false)
                    {
                        Write-Warning -Message "  OUTPUT: $invokeGitOutput"
                    }
                    if ([System.String]::IsNullOrWhiteSpace($invokeGitError) -eq $false)
                    {
                        Write-Warning -Message "  ERROR: $invokeGitError"
                    }
                }
            }
        }
    }
    catch {
        $e = $_

        Write-Error -Message $e.Exception.Message
    }
    finally {

        $exitCode = $process.ExitCode
        $process.Dispose()
    }

    return $exitCode
}
