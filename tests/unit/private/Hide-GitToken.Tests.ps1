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
    Describe 'Hide-GitToken' {
        Context 'When invoked' {

            $testCommands = @(
                @{ 'Command' = @('status');             'ReturnedMessage' = 'status'        },
                @{ 'Command' = @('status','-v');        'ReturnedMessage' = 'status -v...'  },
                @{ 'Command' = @('status','--verbose'); 'ReturnedMessage' = 'status --v...' }
            )

            It "Should input: '<Command>'  output: '<ReturnedMessage>'" -TestCases $testCommands {
                param( $Command, $ReturnedMessage )

                $result = Hide-GitToken -Command $Command

                $result -eq $ReturnedMessage | Should -Be $true
            }
        }
    }
}
