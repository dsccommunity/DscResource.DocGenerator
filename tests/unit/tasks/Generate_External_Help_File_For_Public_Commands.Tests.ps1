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

Describe 'Generate_Markdown_For_Public_Commands' {
    BeforeAll {
        Mock -Command Get-BuiltModuleVersion -MockWith {
            return [PSCustomObject]@{
                Version          = '1.0.0-preview1'
                PreReleaseString = 'preview1'
                ModuleVersion    = '1.0.0'
            }
        }

        Mock -CommandName Get-SamplerBuiltModuleManifest
        Mock -CommandName Get-SamplerBuiltModuleBase -MockWith {
            return $TestDrive.FullName
        }

        Mock -CommandName Get-Module -MockWith {
            return [PSCustomObject] @{
                Name = 'PlatyPS'
            }
        }

        New-Item -Path "$($TestDrive.FullName)/WikiContent" -ItemType 'Directory' -Force | Out-Null

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/Get-Something.md" -Value @'
---
external help file: MockModule-help.xml
Module Name: MockModule
online version:
schema: 2.0.0
Type: Command
---

# Get-Something

## SYNOPSIS
Mock synopsis

## SYNTAX

```
Get-Something -Value <String> [<CommonParameters>]
```

## DESCRIPTION
Mock description

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-Something -Value 'a'
```

Mock example description

## PARAMETERS

### -Value
Mock parameter value description

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Object

## NOTES

## RELATED LINKS
'@
    }

    It 'Should export the build script alias' {
        $buildTaskName = 'Generate_External_Help_File_For_Public_Commands'
        $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

        $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

        $script:buildScript.Name | Should -Be $buildScriptAliasName
        $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
    }

    It 'Should reference an existing build script' {
        Test-Path -Path $script:buildScript.Definition | Should -BeTrue
    }
5
    It 'Should run the build task without throwing' {
        {
            $taskParameters = @{
                ProjectName = 'MockModule'
                ProjectPath = $TestDrive.FullName
                OutputDirectory = $TestDrive.FullName
                # Using the markdown created when the project was built.
                DocOutputFolder = $TestDrive.FullName | Join-Path -ChildPath 'WikiContent'
                SourcePath = "$($TestDrive.FullName)/source"
                HelpCultureInfo = 'en-US'
            }

            Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
        } | Should -Not -Throw

        Should -Exist -ActualValue (Join-Path -Path $TestDrive.FullName -ChildPath 'en-US/MockModule-help.xml') -Because 'the task should have generated the external help file from the markdown.'
    }

    Context 'When there is no external help file created' {
        It 'Should run the build task without throwing' {
            Mock -CommandName Write-Warning
            Mock -CommandName Get-Item -ParameterFilter {
                $Path -eq (Join-Path -Path $TestDrive.FullName -ChildPath 'en-US/MockModule-help.xml')
            } -MockWith {
                return $null
            }

            {
                $taskParameters = @{
                    ProjectName = 'MockModule'
                    ProjectPath = $TestDrive.FullName
                    OutputDirectory = $TestDrive.FullName
                    # Using the markdown created when the project was built.
                    DocOutputFolder = $TestDrive.FullName | Join-Path -ChildPath 'WikiContent'
                    SourcePath = "$($TestDrive.FullName)/source"
                    HelpCultureInfo = 'en-US'
                }

                Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
            } | Should -Not -Throw

            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It
        }
    }
}
