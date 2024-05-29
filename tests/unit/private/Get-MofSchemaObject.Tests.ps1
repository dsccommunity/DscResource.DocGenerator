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
    Describe Get-MofSchemaObject -Skip:$IsLinux {
        BeforeAll {
            $script:className = 'MSFT_MofHelperTest'
            $script:fileName = '{0}.schema.mof' -f $script:ClassName
            $script:tempFileName = '{0}.tmp' -f $script:fileName
            $script:filePath = Join-Path -Path $TestDrive -ChildPath $script:fileName
            $script:tempFilePath = Join-Path -Path $TestDrive -ChildPath $script:tempFileName

            $script:fileContent = @"
[ClassVersion("1.0.0"), FriendlyName("MofHelperTest")]
class MSFT_MofHelperTest : OMI_BaseResource
{
    [Key,      Description("Test key string property")] String Name;
    [Required, Description("Test required property"), ValueMap{"Present","Absent"}, Values{"Present","Absent"}] String Needed;
    [Write,    Description("Test writeable string array")] String MultipleValues[];
    [Write,    Description("Test writeable boolean")] Boolean Switch;
    [Write,    Description("Test writeable datetime")] DateTime ExecuteOn;
    [Write,    Description("Test credential"), EmbeddedInstance("MSFT_Credential")] String Credential;
    [Read,     Description("Test readonly integer")] Uint32 NoWrite;
};
"@
            Set-Content -Path $script:filePath -Value $script:fileContent

            Mock -CommandName Resolve-Path -MockWith {
                [PSCustomObject]@{
                    Path = $script:filePath
                }
            } -ParameterFilter {$Path -eq $script:fileName}

            Mock -CommandName Join-Path -MockWith {
                $script:tempFilePath
            }
        }

        if ($IsMacOs)
        {
            It 'Should throw a not implemented error' {
                { Get-MofSchemaObject -FileName $script:filePath -Verbose } | Should -Throw 'NotImplemented'
            }
        }
        else
        {
            It 'Should import the class from the schema file without throwing' {
                { Get-MofSchemaObject -FileName $script:filePath -Verbose } | Should -Not -Throw
            }

            $schema = Get-MofSchemaObject -FileName $script:filePath -Verbose

            It "Should import class with ClassName $script:className" {
                $schema.ClassName | Should -Be $script:className
            }

            It 'Should get class version' {
                $schema.ClassVersion | Should -Be '1.0.0'
            }

            It 'Should get class FriendlyName' {
                $schema.FriendlyName | Should -Be 'MofHelperTest'
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

            Context 'When the schema is formatted differently but still valid' {
                Context 'When the colon is not prefix with whitespace' {
                    BeforeAll {
                        # Regression test for https://github.com/dsccommunity/DscResource.Test/issues/65.
                        $script:fileContent = @"
[ClassVersion("1.0.0.0"), FriendlyName("MofHelperTest")]
class MSFT_MofHelperTest: OMI_BaseResource
{
    [Key,      Description("Test key string property")] String Name;
};
"@

                        Set-Content -Path $script:filePath -Value $fileContent -Force
                    }

                    It 'Should import the class from the schema file without throwing' {
                        { Get-MofSchemaObject -FileName $script:filePath -Verbose } | Should -Not -Throw
                    }
                }

                Context 'When the colon is suffixed with two whitespaces' {
                    BeforeAll {
                        # Regression test for https://github.com/dsccommunity/DscResource.Test/issues/65.
                        $script:fileContent = @"
[ClassVersion("1.0.0.0"), FriendlyName("MofHelperTest")]
class MSFT_MofHelperTest :  OMI_BaseResource
{
    [Key,      Description("Test key string property")] String Name;
};
"@

                        Set-Content -Path $script:filePath -Value $fileContent -Force
                    }

                    It 'Should import the class from the schema file without throwing' {
                        { Get-MofSchemaObject -FileName $script:filePath -Verbose } | Should -Not -Throw
                    }
                }

                Context 'When the colon is neither prefixed or suffixed by whitespace' {
                    BeforeAll {
                        # Regression test for https://github.com/dsccommunity/DscResource.Test/issues/65.
                        $script:fileContent = @"
[ClassVersion("1.0.0.0"), FriendlyName("MofHelperTest")]
class MSFT_MofHelperTest :  OMI_BaseResource
{
    [Key,      Description("Test key string property")] String Name;
};
"@

                        Set-Content -Path $script:filePath -Value $fileContent -Force
                    }

                    It 'Should import the class from the schema file without throwing' {
                        { Get-MofSchemaObject -FileName $script:filePath -Verbose } | Should -Not -Throw
                    }
                }
            }

            Context 'When the resource is using embedded instances' {
                BeforeAll {
                    $script:fileContent = @"
[ClassVersion("1.0.0.0"), FriendlyName("MofHelperTest")]
class MSFT_MofHelperTest :  OMI_BaseResource
{
    [Key, EmbeddedInstance("DSCTEST_TestEmbeddedInstance"), Description("Test key embedded instance property")] String Name;
};

[ClassVersion("1.0.0"), FriendlyName("TestEmbeddedInstance")]
class DSCTEST_TestEmbeddedInstance
{
    [Key, Description("Test key string property")] String Name;
};

"@

                    Set-Content -Path $script:filePath -Value $fileContent -Force
                }

                It 'Should import the classes from the schema file without throwing' {
                    $result = Get-MofSchemaObject -FileName $script:filePath -Verbose

                    $result | Should -HaveCount 2
                    $result.ClassName | Should -Contain 'MSFT_MofHelperTest'
                    $result.ClassName | Should -Contain 'DSCTEST_TestEmbeddedInstance'
                }
            }
        }
    }
}
