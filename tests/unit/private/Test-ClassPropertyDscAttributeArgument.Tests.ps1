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
    Describe 'Test-ClassPropertyDscAttributeArgument' {
        Context 'When testing if a property is ''Key''' {
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
                        [System.String] $ProjectName
                    }

                    [AzDevOpsProject].GetProperties()
                }

                $mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return $true' {
                $mockAttributes = @{
                    PropertyAttributes = $mockProperties[0].CustomAttributes
                }

                $result = Test-ClassPropertyDscAttributeArgument -IsKey @mockAttributes

                $result | Should -BeTrue
            }

            Context 'When testing if a Key property is mandatory' {
                It 'Should return $true' {
                    $mockAttributes = @{
                        PropertyAttributes = $mockProperties[0].CustomAttributes
                    }

                    $result = Test-ClassPropertyDscAttributeArgument -IsMandatory @mockAttributes

                    $result | Should -BeTrue
                }
            }
        }

        Context 'When testing if a property is ''Write''' {
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
                        [System.String] $ProjectName

                        [DscProperty()]
                        [System.String] $ProjectId
                    }

                    [AzDevOpsProject].GetProperties()
                }

                $mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return $true' {
                $mockAttributes = @{
                    PropertyAttributes = $mockProperties[1].CustomAttributes
                }

                # Makes sure to test the second property (since Key is always needed)
                $result = Test-ClassPropertyDscAttributeArgument -IsWrite @mockAttributes

                $result | Should -BeTrue
            }
        }

        Context 'When testing if a property is ''Mandatory''' {
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
                        [System.String] $ProjectName

                        [DscProperty(Mandatory)]
                        [System.String] $ProjectId
                    }

                    [AzDevOpsProject].GetProperties()
                }

                $mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return $true' {
                $mockAttributes = @{
                    PropertyAttributes = $mockProperties[1].CustomAttributes
                }

                # Makes sure to test the second property (since Key is always needed)
                $result = Test-ClassPropertyDscAttributeArgument -IsMandatory @mockAttributes

                $result | Should -BeTrue
            }
        }

        Context 'When testing if a property is ''Read''' {
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
                        [System.String] $ProjectName

                        [DscProperty(NotConfigurable)]
                        [System.String] $ProjectId
                    }

                    [AzDevOpsProject].GetProperties()
                }

                $mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return $true' {
                $mockAttributes = @{
                    PropertyAttributes = $mockProperties[1].CustomAttributes
                }

                # Makes sure to test the second property (since Key is always needed)
                $result = Test-ClassPropertyDscAttributeArgument -IsRead @mockAttributes

                $result | Should -BeTrue
            }
        }

        Context 'When testing if a property have the expected State property but it does not' {
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
                        [System.String] $ProjectName

                        [DscProperty(NotConfigurable)]
                        [System.String] $ProjectId
                    }

                    [AzDevOpsProject].GetProperties()
                }

                $mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return $false' {
                $mockAttributes = @{
                    PropertyAttributes = $mockProperties[0].CustomAttributes
                }

                # Makes sure to test the second property (since Key is always needed)
                $result = Test-ClassPropertyDscAttributeArgument -IsRead @mockAttributes

                $result | Should -BeFalse
            }
        }
    }
}
