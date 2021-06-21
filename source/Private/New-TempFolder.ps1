<#
    .SYNOPSIS
        Creates a new temporary folder with a random name.

    .EXAMPLE
        New-TempFolder

        This command creates a new temporary folder with a random name.

    .PARAMETER MaximumRetries
        Specifies the maximum number of time to retry creating the temp folder.

    .OUTPUTS
        System.IO.DirectoryInfo
#>
function New-TempFolder
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [CmdletBinding()]
    [OutputType([System.IO.DirectoryInfo])]
    param
    (
        [Parameter()]
        [System.Int32]
        $MaximumRetries = 10
    )

    $tempPath = [System.IO.Path]::GetTempPath()

    $retries = 0

    do
    {
        $retries++

        if ($retries -gt $MaximumRetries)
        {
            throw ($localizedData.NewTempFolderCreationError -f $tempPath)
        }

        $name = [System.IO.Path]::GetRandomFileName()

        $path = New-Item -Path $tempPath -Name $name -ItemType Directory -ErrorAction SilentlyContinue
    } while (-not $path)

    return $path
}
