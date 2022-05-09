<#
    .SYNOPSIS
        Invokes a git command.

    .DESCRIPTION
        Invokes a git command with command line arguments using System.Diagnostics.Process.

        Throws an error when git ExitCode -ne 0 and -PassThru switch -eq $false (or omitted).

    .PARAMETER WorkingDirectory
        The path to the git working directory.

    .PARAMETER Timeout
        Milliseconds to wait for process to exit.

    .PARAMETER PassThru
        Switch parameter when enabled will return result object of running git command.

    .PARAMETER Arguments
        The arguments to pass to the Git executable.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'clone', 'https://github.com/X-Guardian/xActiveDirectory.wiki.git', '--quiet' )

        Invokes the Git executable to clone the specified repository to the working directory.

    .EXAMPLE
        Invoke-Git -WorkingDirectory 'C:\SomeDirectory' -Arguments @( 'status' ) -TimeOut 10000 -PassThru

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

        [Parameter()]
        [System.Int32]
        $TimeOut = 120000,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru,

        [Parameter(ValueFromRemainingArguments = $true)]
        [System.String[]]
        $Arguments
    )

    $gitResult = @{
        'ExitCode'         = -1
        'StandardOutput'   = ''
        'StandardError'    = ''
    }

    Write-Verbose -Message ($script:localizedData.InvokingGitMessage -f ($Arguments -join ' '))

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
            $outGitResultSplat = $gitResult.Clone()

            $outGitResultSplat.Add('Command', $Arguments)
            $outGitResultSplat.Add('WorkingDirectory', $WorkingDirectory)

            Out-GitResult @outGitResultSplat
        }

        if ($gitResult.ExitCode -ne 0 -and $PassThru -eq $false)
        {
            $throwMessage = "$($script:localizedData.InvokeGitCommandDebug -f $(Hide-GitToken -Command $Arguments))`n" +`
                            "$($script:localizedData.InvokeGitExitCodeMessage -f $gitResult.ExitCode)`n" +`
                            "$($script:localizedData.InvokeGitStandardOutputMessage -f $gitResult.StandardOutput)`n" +`
                            "$($script:localizedData.InvokeGitStandardErrorMessage -f $gitResult.StandardError)`n"

            throw $throwMessage
        }
    }

    if ($PSBoundParameters['PassThru'] -eq $true)
    {
        return $gitResult
    }
}
