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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return $true' {
                $result = Test-PropertyMemberAst -Ast $propertyMemberAst[0] -IsKey

                $result | Should -BeTrue
            }

            Context 'When testing if a Key property is mandatory' {
                It 'Should return $true' {
                    $result = Test-PropertyMemberAst -Ast $propertyMemberAst[0] -IsMandatory

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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return $true' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Test-PropertyMemberAst -Ast $propertyMemberAst[1] -IsWrite

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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return $true' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Test-PropertyMemberAst -Ast $propertyMemberAst[1] -IsMandatory

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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return $true' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Test-PropertyMemberAst -Ast $propertyMemberAst[1] -IsRead

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
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.PropertyMemberAst]
                }

                $propertyMemberAst = $mockClassBasedScript.Ast.FindAll($astFilter, $false)
            }

            It 'Should return $false' {
                # Makes sure to test the second property (since Key is always needed)
                $result = Test-PropertyMemberAst -Ast $propertyMemberAst[0] -IsRead

                $result | Should -BeFalse
            }
        }
    }
}
