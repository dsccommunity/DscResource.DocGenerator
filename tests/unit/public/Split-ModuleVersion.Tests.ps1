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

Describe 'Split-ModuleVersion' {
    Context 'When module version have prerelease string' {
        It 'Should return the correct version' {
            $result = Split-ModuleVersion -ModuleVersion '1.2.3-preview0001'

            $result | Should -BeOfType [PSCustomObject]
            $result.Version | Should -Be '1.2.3'
            $result.PreReleaseString | Should -Be 'preview0001'
            $result.ModuleVersion | Should -Be '1.2.3-preview0001'
        }
    }
}
