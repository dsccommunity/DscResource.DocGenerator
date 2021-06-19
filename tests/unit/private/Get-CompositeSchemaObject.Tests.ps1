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
            $script:name = 'CompositeHelperTest'
            $script:moduleVersion = '1.0.0'
            $script:description = 'Composite resource.'
            $script:schemaFileName = '{0}.schema.psm1' -f $script:name
            $script:schemaFilePath = Join-Path -Path $TestDrive -ChildPath $script:schemaFileName

            $script:schemaFileContent = @'
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
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    # Composite resource code would be here.
}
'@
            Set-Content -Path $script:schemaFilePath -Value $script:schemaFileContent

            $script:manifestFileName = '{0}.psd1' -f $script:name
            $script:manifestFilePath = Join-Path -Path $TestDrive -ChildPath $script:manifestFileName

            $script:manifestFileContent = @"
@{
    RootModule        = '$script:name.schema.psm1'
    ModuleVersion     = '$script:moduleVersion'
    GUID              = 'c5e227b5-52dc-4653-b08f-6d94e06bb90b'
    Author            = 'DSC Community'
    CompanyName       = 'DSC Community'
    Copyright         = 'Copyright the DSC Community contributors. All rights reserved.'
    Description       = '$script:description'
    PowerShellVersion = '4.0'
}
"@

            Set-Content -Path $script:manifestFilePath -Value $script:manifestFileContent
        }

        if ($IsMacOs)
        {
            It 'Should throw a not implemented error on MacOS' {
                {
                    Get-CompositeSchemaObject -FileName $script:schemaFilePath -Verbose
                } | Should -Throw 'NotImplemented'
            }
        }
        else
        {
            It 'Should process the composite resource from the schema file without throwing' {
                {
                    $script:schema = Get-CompositeSchemaObject -FileName $script:schemaFilePath -Verbose
                } | Should -Not -Throw
            }

            It "Should return the composite resource schema with name '$script:name'" {
                $script:schema.Name | Should -Be $script:name
            }

            It "Should return the composite resource schema with module version '$script:moduleVersion'" {
                $script:schema.ModuleVersion | Should -Be $script:moduleVersion
            }

            It "Should return the composite resource schema with description '$script:description'" {
                $script:schema.Description | Should -Be $script:description
            }

            It 'Should get property <PropertyName> with all correct properties' {
                [CmdletBinding()]
                param (
                    [Parameter()]
                    [System.String]
                    $Name,

                    [Parameter()]
                    [System.String]
                    $State,

                    [Parameter()]
                    [System.String]
                    $Type,

                    [Parameter()]
                    [System.String]
                    $Description
                )

                $parameter = $script:schema.Parameters.Where({
                    $_.Name -eq $Name
                })

                $parameter.State | Should -Be $State
                $parameter.Type | Should -Be $Type
                $parameter.Description | Should -Be $Description
            } -TestCases @(
                @{
                    Name = 'Name'
                    State = 'Required'
                    Type = 'System.String[]'
                    Description = 'An array of the names.'
                }
                @{
                    Name = 'Ensure'
                    State = 'Write'
                    Type = 'System.String'
                    Description = 'Specifies whether or not the the thing should exist.'
                }
                @{
                    Name = 'Credential'
                    State = 'Write'
                    Type = 'System.Management.Automation.PSCredential'
                    Description = 'The credential to use to set the thing.'
                }
            )

            It 'Should return the proper ValidateSet' {
                $parameter = $script:schema.Parameters.Where({
                    $_.Name -eq 'Ensure'
                })
                $parameter.ValidateSet | Should -HaveCount 2
                $parameter.ValidateSet | Should -Contain 'Absent'
                $parameter.ValidateSet | Should -Contain 'Present'
            }
        }
    }
}
