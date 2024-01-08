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

Describe 'New-GitHubWikiSidebar' {
    BeforeAll {
        $documentationPath = "$script:projectPath\output\WikiContent"
        $outputFilePath = $TestDrive.FullName  | Join-Path -ChildPath 'CustomSidebar.md'

        Mock -CommandName Out-File -ModuleName $script:moduleName
        Mock -CommandName Write-Information -ModuleName $script:moduleName
    }

    Context 'When provided with valid inputs' {
        Context 'When using parameter Force' {
            It 'Should not throw any exceptions and call Out-File with correct parameters' {
                {
                    New-GitHubWikiSidebar -DocumentationPath $documentationPath -OutputPath $TestDrive -SidebarFileName 'CustomSidebar.md' -Force
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $outputFilePath -and $Force -eq $false
                } -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
            }
        }

        Context 'When using parameter Confirm set to $false' {
            It 'Should call Out-File with Force parameter set to true' {
                New-GitHubWikiSidebar -DocumentationPath $documentationPath -OutputPath $TestDrive -SidebarFileName 'CustomSidebar.md' -Confirm:$false

                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $outputFilePath -and $Force -eq $false
                } -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
            }
        }

        Context 'When ReplaceExisting parameter is used' {
            It 'Should call Out-File with Force parameter set to true' {
                New-GitHubWikiSidebar -DocumentationPath $documentationPath -OutputPath $TestDrive -SidebarFileName 'CustomSidebar.md' -ReplaceExisting -Force

                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $outputFilePath -and $Force -eq $true
                } -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
            }
        }
    }

    It 'Should not call Out-File when using parameter WhatIf' {
        New-GitHubWikiSidebar -DocumentationPath $documentationPath -OutputPath $TestDrive -SidebarFileName 'CustomSidebar.md' -ReplaceExisting -WhatIf

        Assert-MockCalled -CommandName Out-File -Exactly -Times 0 -Scope It -ModuleName $script:moduleName
    }

    Context 'When provided with invalid inputs' {
        It 'Should throw an exception if DocumentationPath does not exist' {
            {
                New-GitHubWikiSidebar -DocumentationPath './nonexistent/path' -OutputPath './output' -SidebarFileName 'CustomSidebar.md'
            } | Should -Throw
        }

        It 'Should throw an exception if OutputPath does not exist' {
            {
                New-GitHubWikiSidebar -DocumentationPath $documentationPath -OutputPath './nonexistent/path' -SidebarFileName 'CustomSidebar.md'
            } | Should -Throw
        }
    }
}
