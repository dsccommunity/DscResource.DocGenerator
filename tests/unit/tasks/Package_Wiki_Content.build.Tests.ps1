region HEADER
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

Describe 'Package_Wiki_Content' {
    BeforeAll {
        # Mock Join-Path
        Mock -CommandName Join-Path
        # Mock Test Path
        Mock -CommandName Test-Path
        # Mock Compress Archive
        Mock -CommandName Compress-Archive
    }

    Context 'When the Wiki output path does not exist' {
        It 'Should throw an exception' {

        }

        It 'Should call expected mocks' {

        }
    }

    Context 'When the Wiki output path exists' {
        It 'Should not throw' {

        }

        It 'Should call expected mocks' {

        }
    }
}
