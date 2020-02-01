# This is added to the top of the generated file module file.

$script:resourceHelperModulePath = Join-Path -Path $PSScriptRoot -ChildPath '.\Modules\DscResource.Common'

Import-Module -Name $script:resourceHelperModulePath

$script:localizedData = Get-LocalizedData -DefaultUICulture 'en-US'

<#
    Define enumeration for use by help example generation to determine the type of
    block that a text line is within.
#>
if (-not ([System.Management.Automation.PSTypeName]'HelpExampleBlockType').Type)
{
    $typeDefinition = @'
    public enum HelpExampleBlockType
    {
        None,
        PSScriptInfo,
        Configuration,
        ExampleCommentHeader
    }
'@
    Add-Type -TypeDefinition $typeDefinition
}
