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
    Describe 'Get-ClassPropertyCustomAttribute' {
        BeforeAll {
            $mockClassBasedScript = {
                [DscResource()]
                class AzDevOpsProject
                {
                    [AzDevOpsProject] Get()
                    {
                        return [AzDevOpsProject] $this
                    }

                    [System.Boolean] Test()
                    {
                        return $true
                    }

                    [void] Set()
                    {
                    }

                    [DscProperty(Key)]
                    [System.String]
                    $ProjectName

                    [ValidateSet('value1', 'value2')]
                    [System.String]
                    $ProjectId

                    [DscProperty()]
                    [ValidateRange(0, 1000)]
                    [Nullable[System.Int32]]
                    $Index
                }

                [AzDevOpsProject].GetProperties()
            }

            [System.Reflection.PropertyInfo[]]$mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
        }

        Context 'When searching for ''DscAttribute''' {
            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[0].CustomAttributes
                    AttributeType = 'DscPropertyAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -Not -BeNullOrEmpty
                $result.NamedArguments.MemberName | Should -Be 'Key'
            }

            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[1].CustomAttributes
                    AttributeType = 'DscPropertyAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -BeNullOrEmpty
            }

            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[2].CustomAttributes
                    AttributeType = 'DscPropertyAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -Not -BeNullOrEmpty
            }
        }

        Context 'When searching for ''ValidateSetAttribute''' {
            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[0].CustomAttributes
                    AttributeType = 'ValidateSetAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -BeNullOrEmpty
            }

            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[1].CustomAttributes
                    AttributeType = 'ValidateSetAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -Not -BeNullOrEmpty
            }

            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[2].CustomAttributes
                    AttributeType = 'ValidateSetAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -BeNullOrEmpty
            }
        }

        Context 'When searching for ''ValidateRangeAttribute''' {
            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[0].CustomAttributes
                    AttributeType = 'ValidateRangeAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -BeNullOrEmpty
            }

            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[1].CustomAttributes
                    AttributeType = 'ValidateRangeAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -BeNullOrEmpty
            }

            It 'Should return expected attributes' {
                $mockParameters = @{
                    Attributes    = $mockProperties[2].CustomAttributes
                    AttributeType = 'ValidateRangeAttribute'
                }

                [System.Reflection.CustomAttributeData] $result = Get-ClassPropertyCustomAttribute @mockParameters

                $result | Should -Not -BeNullOrEmpty
            }
        }
    }
}
