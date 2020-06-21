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
    Describe 'Set-WikiModuleVersion' {
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
        }

        Context 'When module version should be set in a markdown file' {
            BeforeAll {
                Mock -CommandName Get-Content
                Mock -CommandName Out-File
            }

            It 'Should not throw an exception' {
                { Set-WikiModuleVersion -Path $TestDrive -ModuleVersion '1.0.0' } | Should -Not -Throw
            }

            It 'Should update the file' {
                Assert-MockCalled -CommandName Out-File -Exactly -Times 1 -Scope Context
            }
        }
    }
}
