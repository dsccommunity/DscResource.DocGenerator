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
    Describe 'Get-ClassResourcePropertyState' {
        Context 'When a property have the named attribute argument ''Key''' {
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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return the state as ''Key''' {
                $result = Get-ClassResourcePropertyState -Ast $propertyMemberAst[0] -Verbose

                $result | Should -Be 'Key'
            }
        }

        Context 'When a property have no named attribute argument' {
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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return the state as ''Write''' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Get-ClassResourcePropertyState -Ast $propertyMemberAst[1] -Verbose

                $result | Should -Be 'Write'
            }
        }

        Context 'When a property have the named attribute argument ''Mandatory''' {
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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return the state as ''Required''' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Get-ClassResourcePropertyState -Ast $propertyMemberAst[1] -Verbose

                $result | Should -Be 'Required'
            }
        }

        Context 'When a property have the named attribute argument ''NotConfigurable''' {
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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return the state as ''Read''' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Get-ClassResourcePropertyState -Ast $propertyMemberAst[1] -Verbose

                $result | Should -Be 'Read'
            }
        }
    }
}
