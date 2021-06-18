#region HEADER
$script:projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:moduleName = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

Import-Module $script:moduleName -Force -ErrorAction 'Stop'
#endregion HEADER

InModuleScope $script:moduleName {
    Describe Get-CompositeSchemaObject {
        BeforeAll {
            $script:className = 'CompositeHelperTest'
            $script:classVersion = '1.0.0'
            $script:schemaFileName = '{0}.schema.psm1' -f $script:className
            $script:tempSchemaFileName = '{0}.schema.ps1.tmp' -f $script:schemaFileName
            $script:schemaFilePath = Join-Path -Path $TestDrive -ChildPath $script:schemaFileName
            $script:tempSchemaFilePath = Join-Path -Path $TestDrive -ChildPath $script:tempSchemaFileName

            $script:schemaFileContent = @"
<#
    .SYNOPSIS
        A composite DSC resource.

    .PARAMETER Name
        An array of the names.

    .PARAMETER Ensure
        Specifies whether or not the the thing should exist.

    .PARAMETER Credential
        The credential to use to set the thing.
#>
configuration CompositeHelperTest
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    # Composite resource code would be here.
}
"@
            Set-Content -Path $script:schemaFilePath -Value $script:schemaFileContent

            $script:manifestFileName = '{0}.psd1' -f $script:className
            $script:tempManifestFileName = '{0}.psd1.tmp' -f $script:manifestFileName
            $script:manifestFilePath = Join-Path -Path $TestDrive -ChildPath $script:manifestFileName
            $script:tempManifestFilePath = Join-Path -Path $TestDrive -ChildPath $script:tempManifestFileName

            $script:manifestFileContent = @"
@{
    RootModule        = '$script:className.schema.psm1'
    ModuleVersion     = '$script:classVersion'
    GUID              = 'c5e227b5-52dc-4653-b08f-6d94e06bb90b'
    Author            = 'DSC Community'
    CompanyName       = 'DSC Community'
    Copyright         = 'Copyright the DSC Community contributors. All rights reserved.'
    Description       = 'Composite resource.'
    PowerShellVersion = '4.0'
}
"@

            Set-Content -Path $script:manifestFilePath -Value $script:manifestFileContent

            Mock -CommandName Resolve-Path -MockWith {
                [PSCustomObject]@{
                    Path = $script:schemaFilePath
                }
            } -ParameterFilter {
                $Path -eq $script:schemaFileName
            }

            Mock -CommandName Resolve-Path -MockWith {
                [PSCustomObject]@{
                    Path = $script:manifestFilePath
                }
            } -ParameterFilter {
                $Path -eq $script:manifestFileName
            }

            Mock -CommandName Join-Path -MockWith {
                $script:tempSchemaFilePath
            }

            Mock -CommandName Join-Path -MockWith {
                $script:tempManifestFilePath
            }
        }

        It 'Should import the composite resource from the schema file without throwing' {
            {
                $script:schema = Get-CompositeSchemaObject -FileName $script:schemaFilePath -Verbose
            } | Should -Not -Throw
        }

        It "Should import composite resource with className $script:className" {
            $schema.ClassName | Should -Be $script:className
        }

        It 'Should get composite resource version' {
            $schema.ClassVersion | Should -Be $script:classVersion
        }

        It "Should get FriendlyName with className $script:className" {
            $schema.FriendlyName | Should -Be $script:className
        }

        It 'Should get property <PropertyName> with all correct properties' {
            [CmdletBinding()]
            param (
                [Parameter()]
                [System.String]
                $PropertyName,

                [Parameter()]
                [System.String]
                $State,

                [Parameter()]
                [System.String]
                $DataType,

                [Parameter()]
                [System.Boolean]
                $IsArray,

                [Parameter()]
                [System.String]
                $Description
            )

            $property = $schema.Attributes.Where({$_.Name -eq $PropertyName})

            $property.State | Should -Be $State
            $property.DataType | Should -Be $DataType
            $property.Description | Should -Be $Description
            $property.IsArray | Should -Be $IsArray
        } -TestCases @(
            @{
                PropertyName = 'Name'
                State = 'Key'
                DataType = 'String'
                Description = 'Test key string property'
                IsArray = $false
            }
            @{
                PropertyName = 'Needed'
                State = 'Required'
                DataType = 'String'
                Description = 'Test required property'
                IsArray = $false
            }
            @{
                PropertyName = 'MultipleValues'
                State = 'Write'
                DataType = 'StringArray'
                Description = 'Test writeable string array'
                IsArray = $true
            }
            @{
                PropertyName = 'Switch'
                State = 'Write'
                DataType = 'Boolean'
                Description = 'Test writeable boolean'
                IsArray = $false
            }
            @{
                PropertyName = 'ExecuteOn'
                State = 'Write'
                DataType = 'DateTime'
                Description = 'Test writeable datetime'
                IsArray = $false
            }
            @{
                PropertyName = 'Credential'
                State = 'Write'
                DataType = 'Instance'
                Description = 'Test credential'
                IsArray = $false
            }
            @{
                PropertyName = 'NoWrite'
                State = 'Read'
                DataType = 'Uint32'
                Description = 'Test readonly integer'
                IsArray = $false
            }
        )

        It 'Should return the proper ValueMap' {
            $property = $schema.Attributes.Where({$_.Name -eq 'Needed'})
            $property.ValueMap | Should -HaveCount 2
            $property.ValueMap | Should -Contain 'Absent'
            $property.ValueMap | Should -Contain 'Present'
        }

        It 'Should return the proper EmbeddedInstance for Credential' {
            $property = $schema.Attributes.Where({$_.Name -eq 'Credential'})
            $property.EmbeddedInstance | Should -Be 'MSFT_Credential'
        }
    }
}
