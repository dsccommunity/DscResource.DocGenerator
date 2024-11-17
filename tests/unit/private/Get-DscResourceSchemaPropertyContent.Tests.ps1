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
    Describe 'Get-DscResourceSchemaPropertyContent' {
        BeforeAll {
            $mockClassProperties = @(
                @{
                    Name             = 'StringProperty'
                    DataType         = 'String'
                    IsArray          = $false
                    State            = 'Key'
                    Description      = 'Any description'
                    EmbeddedInstance = $null
                    ValueMap         = $null
                }
                @{
                    Name             = 'StringValueMapProperty'
                    DataType         = 'String'
                    IsArray          = $false
                    State            = 'Key'
                    Description      = 'Any description'
                    EmbeddedInstance = $null
                    ValueMap         = @(
                        'Value1'
                        'Value2'
                    )
                }
                @{
                    Name             = 'StringArrayProperty'
                    DataType         = 'String'
                    IsArray          = $true
                    State            = 'Write'
                    Description      = 'Any description'
                    EmbeddedInstance = $null
                    ValueMap         = $null
                }
                @{
                    Name             = 'CredentialProperty'
                    DataType         = 'String'
                    IsArray          = $false
                    State            = 'Write'
                    Description      = 'Any description'
                    EmbeddedInstance = 'MSFT_Credential'
                    ValueMap         = $null
                }
                @{
                    Name             = 'EmbeddedInstanceProperty'
                    DataType         = 'String'
                    IsArray          = $false
                    State            = 'Write'
                    Description      = 'Any description'
                    EmbeddedInstance = 'DSC_Embedded1'
                    ValueMap         = $null
                }
                @{
                    Name             = 'EmbeddedInstanceArrayProperty'
                    DataType         = 'String'
                    IsArray          = $true
                    State            = 'Write'
                    Description      = 'Any description'
                    EmbeddedInstance = 'DSC_Embedded2'
                    ValueMap         = $null
                }
            )
        }

        It 'Should return the expected content as a string array' {
            $result = Get-DscResourceSchemaPropertyContent -Property $mockClassProperties

            $result[0] | Should -Be '| Parameter | Attribute | DataType | Description | Allowed Values |'
            $result[1] | Should -Be '| --- | --- | --- | --- | --- |'
            $result[2] | Should -Be '| **StringProperty** | Key | String | Any description | |'
            $result[3] | Should -Be '| **StringValueMapProperty** | Key | String | Any description | Value1, Value2 |'
            $result[4] | Should -Be '| **CredentialProperty** | Write | PSCredential | Any description | |'
            $result[5] | Should -Be '| **EmbeddedInstanceArrayProperty** | Write | DSC_Embedded2[] | Any description | |'
            $result[6] | Should -Be '| **EmbeddedInstanceProperty** | Write | DSC_Embedded1 | Any description | |'
            $result[7] | Should -Be '| **StringArrayProperty** | Write | String[] | Any description | |'
        }
    }
}
