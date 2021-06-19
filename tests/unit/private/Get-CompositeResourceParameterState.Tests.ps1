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
    Describe 'Get-CompositeResourceParameterState' {
        Context 'When a parameter has the attribute ''Mandatory = $true''' {
            BeforeAll {
                $mockCompositeScript = {
                    configuration CompositeHelperTest
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [ValidateNotNullOrEmpty()]
                            [System.String[]]
                            $Name
                        )
                    }
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }

                $parameterAst = $mockCompositeScript.Ast.FindAll($astFilter, $true)
            }

            if ($IsMacOs)
            {
                It 'Should throw a not implemented error on MacOS' {
                    {
                        Get-CompositeResourceParameterState -Ast $parameterAst[0] -Verbose
                    } | Should -Throw 'NotImplemented'
                }
            }
            else
            {
                It 'Should return the state as ''Required''' {
                    $result = Get-CompositeResourceParameterState -Ast $parameterAst[0] -Verbose

                    $result | Should -Be 'Required'
                }
            }
        }

        Context 'When a parameter has the attribute ''Mandatory = $false''' {
            BeforeAll {
                $mockCompositeScript = {
                    configuration CompositeHelperTest
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter(Mandatory = $false)]
                            [ValidateNotNullOrEmpty()]
                            [System.String[]]
                            $Name
                        )
                    }
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }

                $parameterAst = $mockCompositeScript.Ast.FindAll($astFilter, $true)
            }

            if ($IsMacOs)
            {
                It 'Should throw a not implemented error on MacOS' {
                    {
                        Get-CompositeResourceParameterState -Ast $parameterAst[0] -Verbose
                    } | Should -Throw 'NotImplemented'
                }
            }
            else
            {
                It 'Should return the state as ''Write''' {
                    $result = Get-CompositeResourceParameterState -Ast $parameterAst[0] -Verbose

                    $result | Should -Be 'Write'
                }
            }
        }


        Context 'When a parameter does not have the attribute ''Mandatory''' {
            BeforeAll {
                $mockCompositeScript = {
                    configuration CompositeHelperTest
                    {
                        [CmdletBinding()]
                        param
                        (
                            [Parameter()]
                            [ValidateNotNullOrEmpty()]
                            [System.String[]]
                            $Name
                        )
                    }
                }

                $astFilter = {
                    $args[0] -is [System.Management.Automation.Language.ParameterAst]
                }

                $parameterAst = $mockCompositeScript.Ast.FindAll($astFilter, $true)
            }

            if ($IsMacOs)
            {
                It 'Should throw a not implemented error on MacOS' {
                    {
                        Get-CompositeResourceParameterState -Ast $parameterAst[0] -Verbose
                    } | Should -Throw 'NotImplemented'
                }
            }
            else
            {
                It 'Should return the state as ''Write''' {
                    $result = Get-CompositeResourceParameterState -Ast $parameterAst[0] -Verbose

                    $result | Should -Be 'Write'
                }
            }
        }
    }
}
