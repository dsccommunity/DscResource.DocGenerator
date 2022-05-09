<#
    .SYNOPSIS
        Get-TemporaryPath returns the temporary path for the OS.

    .DESCRIPTION
        The Get-TemporaryPath function will return the temporary
        path specific to the OS. It will return $ENV:Temp when run
        on Windows OS, '/tmp' when run in Linux and $ENV:TMPDIR when
        run on MacOS.

    .EXAMPLE
        Get-TemporaryPath

        Get the temporary path (which will differ between operating system).

    .NOTES
        We use Get-Variable to determine if the OS specific variables are
        defined so that we can mock these during testing. We also use Get-Item
        to get the environment variables so we can also mock these for testing.
#>

function Get-TemporaryPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    $temporaryPath = $null

    switch ($true)
    {
        (-not (Test-Path -Path variable:IsWindows) -or ((Get-Variable -Name 'IsWindows' -ValueOnly -ErrorAction SilentlyContinue) -eq $true))
        {
            # Windows PowerShell or PowerShell 6+
            $temporaryPath = (Get-Item -Path env:TEMP).Value
        }

        ((Get-Variable -Name 'IsMacOs' -ValueOnly -ErrorAction SilentlyContinue) -eq $true)
        {
            $temporaryPath = (Get-Item -Path env:TMPDIR).Value
        }

        ((Get-Variable -Name 'IsLinux' -ValueOnly -ErrorAction SilentlyContinue) -eq $true)
        {
            $temporaryPath = '/tmp'
        }

        default
        {
            throw 'Cannot set the temporary path. Unknown operating system.'
        }
    }

    return $temporaryPath
}
