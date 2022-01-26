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
    Describe 'New-WikiFooter' {
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

            $mockSetWikiFooterParameters = @{
                OutputPath     = $TestDrive
                WikiSourcePath = $TestDrive
            }

            $mockWikiFooterOutputPath = Join-Path -Path $mockSetWikiFooterParameters.OutputPath -ChildPath '_Footer.md'
            $mockWikiFooterWikiSourcePath = Join-Path -Path $mockSetWikiFooterParameters.WikiSourcePath -ChildPath '_Footer.md'

            Mock -CommandName Out-File
        }

        Context 'When there is no pre-existing Wiki footer file' {
            BeforeAll {
                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -eq $mockWikiFooterWikiSourcePath
                } -MockWith {
                    return $false
                }
            }

            It 'Should not throw an exception' {
                { New-WikiFooter @mockSetWikiFooterParameters } | Should -Not -Throw
            }

            It 'Should create the footer file' {
                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $mockWikiFooterOutputPath
                } -Exactly -Times 1 -Scope Context
            }
        }

        Context 'When there is a pre-existing Wiki footer file' {
            BeforeAll {
                Mock -CommandName Test-Path -ParameterFilter {
                    $Path -eq $mockWikiFooterWikiSourcePath
                } -MockWith {
                    return $true
                }
            }

            It 'Should not throw an exception' {
                { New-WikiFooter @mockSetWikiFooterParameters } | Should -Not -Throw
            }

            It 'Should not create the footer file' {
                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $mockWikiFooterOutputPath
                } -Exactly -Times 0 -Scope Context
            }
        }
    }
}
