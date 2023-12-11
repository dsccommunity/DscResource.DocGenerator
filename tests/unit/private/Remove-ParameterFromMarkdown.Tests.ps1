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
    Describe 'Remove-ParameterFromMarkdown' {
        BeforeEach {
            $testFilePath = Join-Path $TestDrive -ChildPath 'TestFile.md'

            $parameterName = '-TestParameter'

            $contentWithParameter = @"
### $parameterName
This is a test parameter.

### -AnotherParameter
This is another test parameter.
"@

            Set-Content -Path $testFilePath -Value $contentWithParameter
        }

        It 'Should remove the specified parameter from the markdown file' {
            Remove-ParameterFromMarkdown -FilePath $testFilePath -ParameterName $parameterName

            $content = Get-Content -Path $testFilePath -Raw
            $content | Should -Not -Match $parameterName
        }

        It 'Should not remove other parameters from the markdown file' {
            $anotherParameterName = '-AnotherParameter'

            Remove-ParameterFromMarkdown -FilePath $testFilePath -ParameterName $parameterName

            $content = Get-Content -Path $testFilePath -Raw
            $content | Should -Match $anotherParameterName
        }

        It 'Should not throw when the specified parameter does not exist in the markdown file' {
            $nonExistentParameterName = '-NonExistentParameter'

            { Remove-ParameterFromMarkdown -FilePath $testFilePath -ParameterName $nonExistentParameterName } | Should -Not -Throw
        }

        It 'Should throw when the file does not exist' {
            $nonExistentFilePath = Join-Path $TestDrive -ChildPath 'NonExistentFile.md'

            { Remove-ParameterFromMarkdown -FilePath $nonExistentFilePath -ParameterName $parameterName } | Should -Throw
        }
    }
}
