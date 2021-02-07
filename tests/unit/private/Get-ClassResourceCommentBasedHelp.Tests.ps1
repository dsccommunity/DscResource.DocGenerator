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
    Describe 'Get-ClassResourceCommentBasedHelp' {
        Context 'When there is a script parse error' {
            BeforeAll {
                # Mock script have not declared a Set-method.
                $mockScriptFileContent = @'
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'MyClassResource.ps1'
                $mockScriptFileContent | Out-File -FilePath $mockFilePath -Encoding ascii -Force

                Mock -CommandName Write-Debug
            }

            It 'Should not throw an exception and call the correct mock' {
                { Get-ClassResourceCommentBasedHelp -Path $mockFilePath -Verbose } | Should -Not -Throw

                Assert-MockCalled -CommandName Write-Debug -ParameterFilter {
                    # Assert the localized string is part of the message
                    $Message -match [System.Text.RegularExpressions.RegEx]::Escape($script:localizedData.IgnoreAstParseErrorMessage -f '')
                } -Exactly -Times 1 -Scope It
            }
        }

        Context 'When returning comment-based help' {
            BeforeAll {
                $mockScriptFileContent = @'
<#
.SYNOPSIS
    A synopsis.

.DESCRIPTION
    A description.

.PARAMETER ProjectName
    ProjectName description.
#>
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                $mockFilePath = Join-Path -Path $TestDrive -ChildPath 'MyClassResource.ps1'
                $mockScriptFileContent | Out-File -FilePath $mockFilePath -Encoding ascii -Force
            }

            It 'Should return the correct comment-based help' {
                $result = Get-ClassResourceCommentBasedHelp -Path $mockFilePath -Verbose

                # Parameter name must be upper-case. Also strip any new lines at the end of the string.
                ($result.Parameters['PROJECTNAME'] -replace '\r?\n+$') | Should -Be 'ProjectName description.'
            }
        }
    }
}
