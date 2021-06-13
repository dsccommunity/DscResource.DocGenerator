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
    Describe 'Get-ClassAst' {
        Context 'When the script file cannot be parsed' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

                $mockBuiltModuleScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'

                # The class DSC resource in the built module.
                $mockBuiltModuleScript = @'
[DscResource()]
class MyDscResource
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [DscProperty(Key)]
    [System.String] $ProjectName
}
'@

                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath -Encoding ascii -Force
            }

            It 'Should throw an error' {
                # This evaluates just part of the expected error message.
                { Get-ClassAst -ScriptFile $mockBuiltModuleScriptFilePath } | Should -Throw "'MyDscResource' is missing a Set method"
            }
        }

        Context 'When the script file is parsed successfully' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

                $mockBuiltModuleScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'

                # The class DSC resource in the built module.
                $mockBuiltModuleScript = @'
class MyBaseClass
{
    [void] MyHelperFunction() {}
}

[DscResource()]
class MyDscResource
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName
}
'@

                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltModuleScriptFilePath -Encoding ascii -Force
            }

            Context 'When returning all classes in the script file' {
                It 'Should return the correct classes' {
                    $astResult = Get-ClassAst -ScriptFile $mockBuiltModuleScriptFilePath

                    $astResult | Should -HaveCount 2
                    $astResult.Name | Should -Contain 'MyDscResource'
                    $astResult.Name | Should -Contain 'MyBaseClass'
                }
            }

            Context 'When returning a single class from the script file' {
                It 'Should return the correct classes' {
                    $astResult = Get-ClassAst -ScriptFile $mockBuiltModuleScriptFilePath -ClassName 'MyBaseClass'

                    $astResult | Should -HaveCount 1
                    $astResult.Name | Should -Be 'MyBaseClass'
                }
            }
        }
    }
}
