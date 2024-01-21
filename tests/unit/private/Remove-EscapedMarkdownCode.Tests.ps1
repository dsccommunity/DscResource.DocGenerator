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
    Describe 'Remove-EscapedMarkdownCode' {
        BeforeEach {
            $testFilePath = Join-Path $TestDrive -ChildPath 'TestFile.md'

            $parameterName = '-TestParameter'

            $contentWithParameter = @"
## DESCRIPTION

Removes escaped inline code-blocks:
This is \`inline code 1\`
This is \`inline code 2\`

Removes escaped links: \[MyLinkName\]

Greater than sign \>
Less than sign \<

Removes quoted blocks:
\> This block should be changed
\> This block should be changed
\> This block should be changed

\`\`\`code block 1\`\`\`e
\`\`\`code block 2\`\`\`

C:\\Path\\To\\File.ps1
"@

            Set-Content -Path $testFilePath -Value $contentWithParameter
        }

        It 'Should remove escaped inline code' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '\\\`inline code 1\\\`'
            $content | Should -Not -Match '\\\`inline code 2\\\`'
        }

        It 'Should remove escaped links from the markdown file' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '\\\[MyLinkName\\\]'
        }

        It 'Should remove escaped quoted blocks from the markdown file' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '\\\> This block should be changed'
        }

        It 'Should remove escaped greater than character from the markdown file' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '\\>'
        }

        It 'Should remove escaped less than character from the markdown file' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '\\<'
        }

        It 'Should remove escaped code blocks from the markdown file' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Not -Match '\\\`\\\`\\\`'
            $content | Should -Not -Match '\`\`\`'
        }

        It 'Should remove escaped path separator from the markdown file' {
            Remove-EscapedMarkdownCode -FilePath $testFilePath

            $content = Get-Content -Path $testFilePath -Raw

            $content | Should -Match 'C:\\Path\\To\\File.ps1'
        }
    }
}
