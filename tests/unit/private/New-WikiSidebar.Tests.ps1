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
    Describe 'New-WikiSideBar' {
        BeforeAll {
            <#
                .NOTES
                    This stub function is created because when original Out-File is
                    mocked in PowerShell 6.x it changes the type of the Encoding
                    parameter to [System.Text.Encoding] which when called with
                    `OutFile -Encoding 'ascii'` fails with the error message
                    "Cannot process argument transformation on parameter 'Encoding'.
                    Cannot convert the "ascii" value of type "System.String" to type
                    "System.Text.Encoding".
            #>
            function Out-File
            {
                [CmdletBinding()]
                param
                (
                    [Parameter(ValueFromPipeline = $true)]
                    [PSObject]
                    $InputObject,

                    [Parameter()]
                    [System.String]
                    $FilePath,

                    [Parameter()]
                    [System.String]
                    $Encoding,

                    [Parameter()]
                    [System.Management.Automation.SwitchParameter]
                    $Force
                )

                throw 'StubNotImplemented'
            }

            $mockSetWikiSideBarParameters = @{
                ModuleName = 'TestResource'
                Path       = $TestDrive
            }

            $mockFileInfo = @(
                @{
                    Name     = 'resource1.md'
                    BaseName = 'resource1'
                    FullName = "$($TestDrive)\resource1.md"
                }
            )

            $wikiSideBarFileBaseName = '_Sidebar.md'
            $wikiSideBarFileFullName = Join-Path -Path $mockSetWikiSideBarParameters.Path -ChildPath $wikiSideBarFileBaseName

            Mock -CommandName Out-File
        }

        Context 'When there is no pre-existing Sidebar file' {
            Context 'When there are markdown files to add to the sidebar' {
                BeforeAll {
                    Mock -CommandName Get-ChildItem -MockWith { $mockFileInfo }
                }

                It 'Should not throw an exception' {
                    { New-WikiSideBar @mockSetWikiSideBarParameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 1 -Scope Context
                    Assert-MockCalled -CommandName Out-File -Exactly -Times 1 -Scope Context
                }
            }
        }

        Context 'When there is a pre-existing Sidebar file' {
            BeforeAll {
                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -eq $wikiSideBarFileFullName
                } -MockWith {
                    return $true
                }
            }

            Context 'When there are markdown files to add to the sidebar' {
                BeforeAll {
                    Mock -CommandName Get-ChildItem -MockWith { $mockFileInfo }
                }

                It 'Should not throw an exception' {
                    { New-WikiSideBar @mockSetWikiSideBarParameters } | Should -Not -Throw
                }

                It 'Should not call any mocks to overwrite the sidebar' {
                    Assert-MockCalled -CommandName Get-ChildItem -Exactly -Times 0 -Scope Context
                    Assert-MockCalled -CommandName Out-File -Exactly -Times 0 -Scope Context
                }
            }
        }
    }
}
