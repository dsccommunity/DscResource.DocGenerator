<#
    .SYNOPSIS
        Get-CompositeResourceSchemaPropertyContent is used to generate the parameter content
        for the wiki page.

    .DESCRIPTION
        Get-CompositeResourceSchemaPropertyContent is used to generate the parameter content
        for the wiki page.

    .PARAMETER Property
        A hash table with properties that is returned by Get-CompositeSchemaObject in
        the property 'property'.

    .PARAMETER UseMarkdown
        If certain text should be output as markdown, for example values of the
        hashtable property ValueMap.

    .EXAMPLE
        $content = Get-CompositeResourceSchemaPropertyContent -Property @(
                @{
                    Name             = 'StringProperty'
                    State            = 'Required'
                    Type             = 'String'
                    ValidateSet      = @('Value1','Value2')
                    Description      = 'Any description'
                }
            )

        Returns the parameter content based on the passed array of parameter metadata.
#>
function Get-CompositeResourceSchemaPropertyContent
{
    [CmdletBinding()]
    [OutputType([System.String[]])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Collections.Hashtable[]]
        $Property,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $UseMarkdown
    )

    $stringArray = [System.String[]] @()

    $stringArray += '| Parameter | Attribute | DataType | Description | Allowed Values |'
    $stringArray += '| --- | --- | --- | --- | --- |'

    foreach ($currentProperty in $Property)
    {
        $propertyLine = "| **$($currentProperty.Name)** " + `
            "| $($currentProperty.State) " + `
            "| $($currentProperty.Type) |"

        if (-not [System.String]::IsNullOrEmpty($currentProperty.Description))
        {
            $propertyLine += ' ' + $currentProperty.Description
        }

        $propertyLine += ' |'

        if (-not [System.String]::IsNullOrEmpty($currentProperty.ValidateSet))
        {
            $valueMap = $currentProperty.ValidateSet

            if ($UseMarkdown.IsPresent)
            {
                $valueMap = $valueMap | ForEach-Object -Process {
                    '`{0}`' -f $_
                }
            }

            $propertyLine += ' ' + ($valueMap -join ', ')
        }

        $propertyLine += ' |'

        $stringArray += $propertyLine
    }

    return (, $stringArray)
}
