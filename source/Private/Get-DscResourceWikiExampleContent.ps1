<#
    .SYNOPSIS
        This function reads an example file from a resource and converts
        it to markdown for inclusion in a resource wiki file.

    .DESCRIPTION
        The function will read the example PS1 file and convert the
        help header into the description text for the example. It will
        also surround the example configuration with code marks to
        indication it is powershell code.

    .PARAMETER ExamplePath
        The path to the example file.

    .PARAMETER ModulePath
        The number of the example.

    .EXAMPLE
        Get-DscResourceWikiExampleContent -ExamplePath 'C:\repos\NetworkingDsc\Examples\Resources\DhcpClient\1-DhcpClient_EnableDHCP.ps1' -ExampleNumber 1

        Reads the content of 'C:\repos\NetworkingDsc\Examples\Resources\DhcpClient\1-DhcpClient_EnableDHCP.ps1'
        and converts it to markdown in preparation for being added to a resource wiki page.
#>

function Get-DscResourceWikiExampleContent
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ExamplePath,

        [Parameter(Mandatory = $true)]
        [System.Int32]
        $ExampleNumber
    )

    $exampleContent = Get-Content -Path $ExamplePath

    # Use a string builder to assemble the example description and code
    $exampleDescriptionStringBuilder = New-Object -TypeName System.Text.StringBuilder
    $exampleCodeStringBuilder = New-Object -TypeName System.Text.StringBuilder

    <#
        Step through each line in the source example and determine
        the content and act accordingly:
        \<#PSScriptInfo...#\> - Drop block
        \#Requires - Drop Line
        \<#...#\> - Drop .EXAMPLE, .SYNOPSIS and .DESCRIPTION but include all other lines
        Configuration ... - Include entire block until EOF
    #>
    $blockType = [WikiExampleBlockType]::None

    foreach ($exampleLine in $exampleContent)
    {
        Write-Debug -Message ('Processing Line: {0}' -f $exampleLine)

        # Determine the behavior based on the current block type
        switch ($blockType.ToString())
        {
            'PSScriptInfo'
            {
                Write-Debug -Message 'PSScriptInfo Block Processing'

                # Exclude PSScriptInfo block from any output
                if ($exampleLine -eq '#>')
                {
                    Write-Debug -Message 'PSScriptInfo Block Ended'

                    # End of the PSScriptInfo block
                    $blockType = [WikiExampleBlockType]::None
                }
            }

            'Configuration'
            {
                Write-Debug -Message 'Configuration Block Processing'

                # Include all lines in the configuration block in the code output
                $null = $exampleCodeStringBuilder.AppendLine($exampleLine)
            }

            'ExampleCommentHeader'
            {
                Write-Debug -Message 'ExampleCommentHeader Block Processing'

                # Include all lines in Example Comment Header block except for headers
                $exampleLine = $exampleLine.TrimStart()

                if ($exampleLine -notin ('.SYNOPSIS', '.DESCRIPTION', '.EXAMPLE', '#>'))
                {
                    # Not a header so add this to the output
                    $null = $exampleDescriptionStringBuilder.AppendLine($exampleLine)
                }

                if ($exampleLine -eq '#>')
                {
                    Write-Debug -Message 'ExampleCommentHeader Block Ended'

                    # End of the Example Comment Header block
                    $blockType = [WikiExampleBlockType]::None
                }
            }

            default
            {
                Write-Debug -Message 'Not Currently Processing Block'

                # Check the current line
                if ($exampleLine.TrimStart() -eq '<#PSScriptInfo')
                {
                    Write-Debug -Message 'PSScriptInfo Block Started'

                    $blockType = [WikiExampleBlockType]::PSScriptInfo
                }
                elseif ($exampleLine -match 'Configuration')
                {
                    Write-Debug -Message 'Configuration Block Started'

                    $null = $exampleCodeStringBuilder.AppendLine($exampleLine)
                    $blockType = [WikiExampleBlockType]::Configuration
                }
                elseif ($exampleLine.TrimStart() -eq '<#')
                {
                    Write-Debug -Message 'ExampleCommentHeader Block Started'

                    $blockType = [WikiExampleBlockType]::ExampleCommentHeader
                }
            }
        }
    }

    # Assemble the final output
    $null = $exampleStringBuilder = New-Object -TypeName System.Text.StringBuilder
    $null = $exampleStringBuilder.AppendLine("### Example $ExampleNumber")
    $null = $exampleStringBuilder.AppendLine()
    $null = $exampleStringBuilder.AppendLine($exampleDescriptionStringBuilder)
    $null = $exampleStringBuilder.AppendLine('```powershell')
    $null = $exampleStringBuilder.Append($exampleCodeStringBuilder)
    $null = $exampleStringBuilder.Append('```')

    return $exampleStringBuilder.ToString()
}
