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
    Describe 'Get-CompositeResourceSchemaPropertyContent' {
        BeforeAll {
            $mockClassProperties = @(
                @{
                    Name             = 'StringProperty'
                    State            = 'Required'
                    Type             = 'String'
                    ValidateSet      = $null
                    Description      = 'Any description'
                }
                @{
                    Name             = 'StringValueMapProperty'
                    State            = 'Required'
                    Type             = 'String'
                    ValidateSet      = @(
                        'Value1'
                        'Value2'
                    )
                    Description      = 'Any description'
                }
                @{
                    Name             = 'StringWriteProperty'
                    State            = 'Write'
                    Type             = 'String'
                    ValidateSet      = $null
                    Description      = 'Any description'
                }
            )
        }

        It 'Should return the expected content as a string array' {
            $result = Get-CompositeResourceSchemaPropertyContent -Property $mockClassProperties

            $result[0] | Should -Be '| Parameter | Attribute | DataType | Description | Allowed Values |'
            $result[1] | Should -Be '| --- | --- | --- | --- | --- |'
            $result[2] | Should -Be '| **StringProperty** | Key | String | Any description | |'
            $result[3] | Should -Be '| **StringValueMapProperty** | Key | String | Any description | Value1, Value2 |'
            $result[4] | Should -Be '| **StringWriteProperty** | Write | String[] | Any description | |'
        }
    }
}
