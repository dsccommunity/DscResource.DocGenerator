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
        if ($PSVersionTable.PSVersion -ge '6.0')
        {
            $mockHyphen = [System.Char]::ConvertFromUtf32(0x2011)
        }
        else
        {
            $mockHyphen = '-'
        }

        $documentationPath = "$($TestDrive.FullName)/WikiContent"
        $outputFilePath = $documentationPath  | Join-Path -ChildPath 'CustomSidebar.md'

        New-Item -Path $documentationPath -ItemType 'Directory' -Force | Out-Null

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/Home.md" -Value @'
# MockModule
'@

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/MockMarkdownWithoutMetadata.md" -Value @'
# Some topic
'@

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/RandomHelpTopic.md" -Value @'
---
Category: Help topics
---

# RandomHelpTopic
'@

        Set-Content -Path ("$($TestDrive.FullName)/WikiContent/Get{0}Something.md" -f $mockHyphen) -Value @'
---
Type: Command
Category: Commands
---

# Get-Something
'@

        Set-Content -Path "$($TestDrive.FullName)/WikiContent/MockResource.md" -Value @'
---
Type: MofResource
Category: Resources
---

# MockResource
'@

        Mock -CommandName Out-File -ModuleName $script:moduleName
        Mock -CommandName Write-Information -ModuleName $script:moduleName
    }

    Context 'When provided with valid inputs' {
        Context 'When using parameter Force' {
            BeforeAll {
                $script:mockWikiContentOutput = @'
[Home](Home)

### General

- [MockMarkdownWithoutMetadata](MockMarkdownWithoutMetadata)

### Commands

- [Get-Something](Get{0}Something)

### Help topics

- [RandomHelpTopic](RandomHelpTopic)

### Resources

- [MockResource](MockResource)
'@

                $script:mockWikiContentOutput = $script:mockWikiContentOutput -replace '\r?\n', "`r`n"
                $script:mockWikiContentOutput = $script:mockWikiContentOutput -f $mockHyphen
            }

            It 'Should not throw any exceptions and call Out-File with correct parameters' {
                {
                    New-GitHubWikiSidebar -DocumentationPath $documentationPath -SidebarFileName 'CustomSidebar.md' -Force
                } | Should -Not -Throw

                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    # This is used to output the diff if the output is not as expected.
                    if ($InputObject -ne $script:mockWikiContentOutput)
                    {
                        # Helper to output the diff.
                        Out-Diff -Expected $script:mockWikiContentOutput -Actual $InputObject
                    }

                    $FilePath -eq $outputFilePath -and $Force -eq $false -and `
                        $InputObject -eq $script:mockWikiContentOutput
                } -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
            }
        }

        Context 'When using parameter Confirm set to $false' {
            It 'Should call Out-File with Force parameter set to true' {
                New-GitHubWikiSidebar -DocumentationPath $documentationPath -SidebarFileName 'CustomSidebar.md' -Confirm:$false

                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $outputFilePath -and $Force -eq $false
                } -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
            }
        }

        Context 'When ReplaceExisting parameter is used' {
            It 'Should call Out-File with Force parameter set to true' {
                New-GitHubWikiSidebar -DocumentationPath $documentationPath -SidebarFileName 'CustomSidebar.md' -ReplaceExisting -Force

                Assert-MockCalled -CommandName Out-File -ParameterFilter {
                    $FilePath -eq $outputFilePath -and $Force -eq $true
                } -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
            }
        }
    }

    It 'Should not call Out-File when using parameter WhatIf' {
        New-GitHubWikiSidebar -DocumentationPath $documentationPath -SidebarFileName 'CustomSidebar.md' -ReplaceExisting -WhatIf

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

    Context 'When sidebar filename already exist' {
        BeforeAll {
            Mock -CommandName Out-File -ModuleName $script:moduleName
            Mock -CommandName Write-Warning -ModuleName $script:moduleName
            Mock -CommandName Test-Path -ModuleName $script:moduleName -ParameterFilter {
                $Path -match 'CustomSidebar.md'
            } -MockWith {
                return $true
            }
        }

        It 'Should write a warning message and not call Out-File' {
            {
                New-GitHubWikiSidebar -DocumentationPath $documentationPath -OutputPath $documentationPath  -SidebarFileName 'CustomSidebar.md'
            } | Should -Not -Throw

            Assert-MockCalled -CommandName Out-File -Exactly -Times 0 -Scope It -ModuleName $script:moduleName
            Assert-MockCalled -CommandName Write-Warning -Exactly -Times 1 -Scope It -ModuleName $script:moduleName
        }
    }
}
