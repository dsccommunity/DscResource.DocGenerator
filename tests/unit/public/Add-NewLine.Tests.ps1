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

Describe 'Add-NewLine' {
    BeforeAll {
        $testFilePath = Join-Path $TestDrive -ChildPath 'TestFile.xml'

        $content = '<xml version="1.0" encoding="utf-8"?>'

        # Use WriteAllText() instead of Set-Content so that a line ending is not added.
        [System.IO.File]::WriteAllText($testFilePath, $content)
    }

    It 'Should add a new line at the end of the file' {
        $originalContent = Get-Content -Path $testFilePath -Raw

        Add-NewLine -FileInfo $testFilePath -AtEndOfFile

        $newContent = Get-Content -Path $testFilePath -Raw

        $originalContent | Should -Not -MatchExactly '\r\n$'
        $newContent | Should -MatchExactly '\r\n$'
    }
}
