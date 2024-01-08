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

Describe 'Remove-MarkdownMetadataBlock' {
    It 'Should remove metadata from a markdown file when -Force is used' {
        $testFilePath = Join-Path -Path $TestDrive -ChildPath 'TestFile.md'

        Set-Content -Path $testFilePath -Value @"
---
title: Test Title
---
# Test Content
"@

        Remove-MarkdownMetadataBlock -FilePath $testFilePath -Force

        $content = Get-Content -Path $testFilePath -Raw

        $content | Should -Not -Match '---'
        $content | Should -Match '# Test Content'
    }

    It 'Should remove metadata from a markdown file when -Confirm:$false is used' {
        $testFilePath = Join-Path -Path $TestDrive -ChildPath 'TestFile.md'

        Set-Content -Path $testFilePath -Value @"
---
title: Test Title
---
# Test Content
"@

        Remove-MarkdownMetadataBlock -FilePath $testFilePath -Confirm:$false

        $content = Get-Content -Path $testFilePath -Raw

        $content | Should -Not -Match '---'
        $content | Should -Match '# Test Content'
    }

    It 'Should not remove metadata from a markdown file when -WhatIf is used' {
        $testFilePath = Join-Path -Path $TestDrive -ChildPath 'TestFileNoForce.md'

        Set-Content -Path $testFilePath -Value @"
---
title: Test Title
---
# Test Content
"@

        Remove-MarkdownMetadataBlock -FilePath $testFilePath -WhatIf

        $content = Get-Content -Path $testFilePath -Raw

        $content | Should -Match '---'
        $content | Should -Match '# Test Content'
    }

    It 'Should not throw when file does not contain metadata' {
        $testFilePathNoMetadata = Join-Path $TestDrive -ChildPath 'TestFileNoMetadata.md'

        Set-Content -Path $testFilePathNoMetadata -Value @"
# Test Content
"@

        { Remove-MarkdownMetadataBlock -FilePath $testFilePathNoMetadata -Confirm:$false } | Should -Not -Throw

        $content = Get-Content -Path $testFilePathNoMetadata -Raw

        $content | Should -Match '# Test Content'
    }

    It 'Should throw when file does not exist' {
        $nonExistentFilePath = Join-Path $TestDrive -ChildPath 'NonExistentFile.md'

        { Remove-MarkdownMetadataBlock -FilePath $nonExistentFilePath -Confirm:$false } | Should -Throw
    }

    It 'Should not modify the file if there is no metadata' {
        $testFilePathNoMetadata = Join-Path $TestDrive -ChildPath 'TestFileNoMetadata.md'

        Set-Content -Path $testFilePathNoMetadata -Value @"
# Test Content
"@
        $originalContent = Get-Content -Path $testFilePathNoMetadata -Raw

        Remove-MarkdownMetadataBlock -FilePath $testFilePathNoMetadata -Confirm:$false

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

        Remove-MarkdownMetadataBlock -FilePath $testFilePath -Confirm:$false

        $content = Get-Content -Path $testFilePath -Raw

        $content[0] | Should -Not -Be "`r"
        $content[0] | Should -Not -Be "`n"
    }

    It 'Should throw when provided with a non-leaf path' {
        $nonLeafPath = Join-Path -Path $TestDrive -ChildPath 'NonLeafPath'

        { Remove-MarkdownMetadataBlock -FilePath $nonLeafPath -Confirm:$false } | Should -Throw
    }

    It 'Should throw when provided with a non-existent path' {
        $nonExistentPath = Join-Path -Path $TestDrive -ChildPath 'NonExistentPath.md'

        { Remove-MarkdownMetadataBlock -FilePath $nonExistentPath -Confirm:$false } | Should -Throw
    }
}
