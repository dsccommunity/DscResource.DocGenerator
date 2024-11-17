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
    Describe 'Get-DscPropertyType' {
        Context 'When the property type is ''Nullable''' {
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

                        [DscProperty(Mandatory)]
                        [System.String]
                        $ProjectId

                        [DscProperty()]
                        [Nullable[System.Int32]]
                        $Index
                    }

                    [AzDevOpsProject].GetProperties()
                }

                [System.Reflection.PropertyInfo[]]$mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return the inner type name' {
                $result = Get-DscPropertyType -PropertyType $mockProperties[2].PropertyType

                $result | Should -Be 'System.Int32'
            }
        }

        Context 'When the property type is not ''Nullable''' {
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

                        [DscProperty(Mandatory)]
                        [System.String]
                        $ProjectId

                        [DscProperty()]
                        [Nullable[System.Int32]]
                        $Index
                    }

                    [AzDevOpsProject].GetProperties()
                }

                [System.Reflection.PropertyInfo[]]$mockProperties = $mockClassBasedScript.InvokeReturnAsIs()
            }

            It 'Should return the type name' {
                $result = Get-DscPropertyType -PropertyType $mockProperties[1].PropertyType

                $result | Should -Be 'System.String'
            }
        }
    }
}
