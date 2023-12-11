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
    Describe 'Remove-MarkdownMetadata' {
        It 'Should remove metadata from a markdown file' {
            $testFilePath = Join-Path -Path $TestDrive -ChildPath 'TestFile.md'

            Set-Content -Path $testFilePath -Value @"
---
title: Test Title
---
# Test Content
"@

            Remove-MarkdownMetadata -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '---'
            $content | Should -Match '# Test Content'
        }

        It 'Should not throw when file does not contain metadata' {
            $testFilePathNoMetadata = Join-Path $TestDrive -ChildPath 'TestFileNoMetadata.md'
            Set-Content -Path $testFilePathNoMetadata -Value @"
# Test Content
"@

            { Remove-MarkdownMetadata -FilePath $testFilePathNoMetadata } | Should -Not -Throw

            $content = Get-Content -Path $testFilePathNoMetadata -Raw

            $content | Should -Match '# Test Content'
        }

        It 'Should throw when file does not exist' {
            $nonExistentFilePath = Join-Path $TestDrive -ChildPath 'NonExistentFile.md'

            { Remove-MarkdownMetadata -FilePath $nonExistentFilePath } | Should -Throw
        }

        It 'Should not modify the file if there is no metadata' {
            $testFilePathNoMetadata = Join-Path $TestDrive -ChildPath 'TestFileNoMetadata.md'

            Set-Content -Path $testFilePathNoMetadata -Value @"
# Test Content
"@
            $originalContent = Get-Content -Path $testFilePathNoMetadata -Raw

            Remove-MarkdownMetadata -FilePath $testFilePathNoMetadata

            $newContent = Get-Content -Path $testFilePathNoMetadata -Raw

            $newContent | Should -BeExactly $originalContent
        }

        It 'Should not have line endings at the top of the file' {
            $testFilePath = Join-Path -Path $TestDrive -ChildPath 'TestFile.md'

            Set-Content -Path $testFilePath -Value @"
---
title: Test Title
---
# Test Content
"@

            Remove-MarkdownMetadata -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content[0] | Should -Not -Be "`r"
            $content[0] | Should -Not -Be "`n"
        }
    }
}
