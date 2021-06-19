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
    Describe 'Get-CompositeResourceParameterValidateSet' {
        Context 'When a parameter has the attribute ''ValidateSet'' with two array values' {
            BeforeAll {
                $mockCompositeScript = {
                    configuration CompositeHelperTest
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter()]
                            [ValidateSet('Present', 'Absent')]
                            [System.String]
                            $Ensure
                        )
                    }
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }

                $parameterAst = $mockCompositeScript.Ast.FindAll($astFilter, $true)
            }

            It 'Should return the expected array' {
                $result = Get-CompositeResourceParameterValidateSet -Ast $parameterAst[0] -Verbose

                $result | Should -HaveCount 2
                $result | Should -Contain 'Present'
                $result | Should -Contain 'Absent'
            }
        }

        Context 'When a parameter has the attribute ''ValidateSet'' with one array value' {
            BeforeAll {
                $mockCompositeScript = {
                    configuration CompositeHelperTest
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter()]
                            [ValidateSet('Present')]
                            [System.String]
                            $Ensure
                        )
                    }
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }

                $parameterAst = $mockCompositeScript.Ast.FindAll($astFilter, $true)
            }

            It 'Should return the expected array' {
                $result = Get-CompositeResourceParameterValidateSet -Ast $parameterAst[0] -Verbose

                $result | Should -HaveCount 1
                $result | Should -Contain 'Present'
            }
        }

        Context 'When a parameter does not have the attribute ''ValidateSet''' {
            BeforeAll {
                $mockCompositeScript = {
                    configuration CompositeHelperTest
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter()]
                            [System.String]
                            $Ensure
                        )
                    }
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }

                $parameterAst = $mockCompositeScript.Ast.FindAll($astFilter, $true)
            }

            It 'Should return the expected array' {
                $result = Get-CompositeResourceParameterValidateSet -Ast $parameterAst[0] -Verbose

                $result | Should -BeNullOrEmpty
            }
        }
    }
}
