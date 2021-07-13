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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../helpers/DscResource.DocGenerator.TestHelper.psm1') -Force

InModuleScope $script:moduleName {
    Describe 'New-DscResourceWikiPage' {
        Context 'When generating documentation for resources' {
            $script:mockOutputPath = Join-Path -Path $TestDrive -ChildPath 'docs'
            $script:mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'module'
            $script:mockBuildModulePath = Join-Path -Path $TestDrive -ChildPath '1.0.0'

            $script:newDscResourceWikiPage_parameters = @{
                SourcePath      = $script:mockSourcePath
                OutputPath      = $script:mockOutputPath
                BuiltModulePath = $script:mockBuildModulePath
                Verbose         = $true
            }

            $script:newDscResourceWikiPage_parameterFilter = {
                $OutputPath -eq $script:mockOutputPath -and `
                $SourcePath -eq $script:mockSourcePath -and `
                $BuiltModulePath -eq $script:mockBuildModulePath
            }

            Mock `
                -CommandName New-DscMofResourceWikiPage `
                -ParameterFilter $script:newDscResourceWikiPage_parameterFilter

            Mock `
                -CommandName New-DscClassResourceWikiPage `
                -ParameterFilter $script:newDscResourceWikiPage_parameterFilter

            Mock `
                -CommandName New-DscCompositeResourceWikiPage `
                -ParameterFilter $script:newDscResourceWikiPage_parameterFilter

            It 'Should not throw an exception' {
                { New-DscResourceWikiPage @script:newDscResourceWikiPage_parameters } | Should -Not -Throw
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName New-DscMofResourceWikiPage `
                    -ParameterFilter $script:newDscResourceWikiPage_parameterFilter `
                    -Exactly -Times 1

                Assert-MockCalled `
                    -CommandName New-DscClassResourceWikiPage `
                    -ParameterFilter $script:newDscResourceWikiPage_parameterFilter `
                    -Exactly -Times 1

                Assert-MockCalled `
                    -CommandName New-DscCompositeResourceWikiPage `
                    -ParameterFilter $script:newDscResourceWikiPage_parameterFilter `
                    -Exactly -Times 1
            }
        }
    }
}
