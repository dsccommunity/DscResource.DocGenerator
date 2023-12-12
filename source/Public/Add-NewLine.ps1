<#
    .SYNOPSIS
        Adds a new line at the end of a file.

    .DESCRIPTION
        The Add-NewLineAtEndOfFile function adds a new line at the end of the specified file.

    .PARAMETER FileInfo
        Specifies the file to which the new line will be added.

    .PARAMETER AtEndOfFile
        Specifies that the new line should be added to the end of the file.

    .EXAMPLE
        Add-NewLineAtEndOfFile -FileInfo "C:\path\to\file.txt" -AtEndOfFile

        Adds a new line at the end of the file located at "C:\path\to\file.txt" without prompting for confirmation.

    .INPUTS
        [System.IO.FileInfo]

        Accepts a FileInfo object representing the file to which the new line will be added.

    .OUTPUTS
        None. The function does not generate any output.
#>
function Add-NewLine
{
    [CmdletBinding()]
    param
    (

        [Parameter(ValueFromPipeline = $true, Mandatory = $true, ParameterSetName = 'AtEndOfFile')]
        [System.IO.FileInfo]
        $FileInfo,

        [Parameter(Mandatory = $true, ParameterSetName = 'AtEndOfFile')]
        [System.Management.Automation.SwitchParameter]
        $AtEndOfFile
    )

    process
    {
        $fileContent = Get-Content -Path $FileInfo.FullName -Raw

        if ($AtEndOfFile.IsPresent)
        {
            $fileContent += "`r`n"
        }

        [System.IO.File]::WriteAllText($FileInfo.FullName, $fileContent)
    }
}
