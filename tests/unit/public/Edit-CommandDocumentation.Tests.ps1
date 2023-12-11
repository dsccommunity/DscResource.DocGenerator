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

Describe 'Edit-CommandDocumentation' {
    BeforeAll {
        Mock -CommandName Write-Information -ModuleName $script:moduleName

        $testFilePath = Join-Path $TestDrive -ChildPath 'TestFile.md'

        $contentWithProgressAction = @"
---
schema: 2.0.0
Type: Command
---
### -ProgressAction
This is a test parameter.

### -AnotherParameter
This is another test parameter.
"@

        Set-Content -Path $testFilePath -Value $contentWithProgressAction
    }

    It 'Should remove the ProgressAction parameter from the markdown file' {
        Edit-CommandDocumentation -FilePath $testFilePath

        $content = Get-Content -Path $testFilePath -Raw

        $content | Should -Not -Match '-ProgressAction'
    }

    It 'Should not remove other parameters from the markdown file' {
        $anotherParameterName = '-AnotherParameter'

        Edit-CommandDocumentation -FilePath $testFilePath

        $content = Get-Content -Path $testFilePath -Raw

        $content | Should -Match $anotherParameterName
    }

    It 'Should throw when the markdown file has an unsupported schema version' {
        $contentWithUnsupportedSchema = @"
---
schema: 3.0.0
Type: Command
---
### -ProgressAction
This is a test parameter.

### -AnotherParameter
This is another test parameter.
"@
        Set-Content -Path $testFilePath -Value $contentWithUnsupportedSchema

        { Edit-CommandDocumentation -FilePath $testFilePath } | Should -Throw
    }

    It 'Should skip the markdown file if the Type is not Command' {
        $contentWithNonCommandType = @"
---
schema: 2.0.0
Type: NonCommand
---
### -ProgressAction
This is a test parameter.

### -AnotherParameter
This is another test parameter.
"@
        Set-Content -Path $testFilePath -Value $contentWithNonCommandType

        { Edit-CommandDocumentation -FilePath $testFilePath } | Should -Not -Throw

        $content = Get-Content -Path $testFilePath -Raw

        $content | Should -Match '-ProgressAction'
        $content | Should -Match '-AnotherParameter'
    }
}
