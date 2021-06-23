
$script:moduleName = 'DscResource.DocGenerator'

# Convert-Path required for PS7 or Join-Path fails
$projectPath = "$($PSScriptRoot)\..\.." | Convert-Path

$sourcePath = (
    Get-ChildItem -Path $projectPath\*\*.psd1 |
        Where-Object -FilterScript {
            ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) `
            -and $(
                try
                {
                    Test-ModuleManifest -Path $_.FullName -ErrorAction 'Stop'
                }
                catch
                {
                    $false
                }
            )
        }
).Directory.FullName

Describe 'Changelog Management' -Tag 'Changelog' {
    It 'Should have updated the Changelog' -skip:(
        -not (
            [System.Boolean] (Get-Command -Name git -ErrorAction 'SilentlyContinue') -and
            [System.Boolean] (& (Get-Process -Id $PID).Path -NoProfile -Command 'git rev-parse --is-inside-work-tree 2>$null')
        )
        ) {
        # Get the list of changed files compared with master
        $headCommit = & git rev-parse HEAD
        $defaultBranchCommit = & git rev-parse origin/main
        $filesChanged = & git @('diff', "$defaultBranchCommit...$headCommit", '--name-only')

        if ($headCommit -ne $defaultBranchCommit)
        {
            # If we're not testing same commit (i.e. main..main)
            $filesChanged.Where{ (Split-Path $_ -Leaf) -match '^changelog' } | Should -Not -BeNullOrEmpty
        }
    }

    It 'Should have the Changelog compliant with the Keepachangelog format' -skip:(-not [System.Boolean] (Get-Command git -ErrorAction 'SilentlyContinue')) {
        {
            Get-ChangelogData -Path (Join-Path -Path $ProjectPath -ChildPath 'CHANGELOG.md') -ErrorAction 'Stop'
        } | Should -Not -Throw
    }
}

Describe 'General module control' -Tags 'FunctionalQuality' {
    It 'Should import without errors' {
        { Import-Module -Name $script:moduleName -Force -ErrorAction Stop } | Should -Not -Throw

        Get-Module -Name $script:moduleName | Should -Not -BeNullOrEmpty
    }

    It 'Should remove without error' {
        { Remove-Module -Name $script:moduleName -ErrorAction Stop } | Should -Not -Throw

        Get-Module -Name $script:moduleName | Should -BeNullOrEmpty
    }
}

#region Build test cases
$script:moduleName = 'DscResource.DocGenerator'

Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

$mut = Get-Module -Name $script:moduleName -ListAvailable |
    Select-Object -First 1 |
    Import-Module -Force -ErrorAction 'Stop' -PassThru

# Must use the imported module to build test cases.
$allModuleFunctions = & $mut { Get-Command -Module $args[0] -CommandType Function } $script:moduleName

# Build test cases.
$testCases = @()

foreach ($function in $allModuleFunctions)
{
    $testCases += @{
        Name = $function.Name
    }

}
#endregion Build test cases

Describe 'Quality for module' -Tags 'TestQuality' {
    if (Get-Command -Name Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue)
    {
        $scriptAnalyzerRules = Get-ScriptAnalyzerRule
    }
    else
    {
        if ($ErrorActionPreference -ne 'Stop')
        {
            Write-Warning -Message 'ScriptAnalyzer not found!'
        }
        else
        {
            throw 'ScriptAnalyzer not found!'
        }
    }

    It 'Should have a unit test for <Name>' -TestCases $testCases {
        param
        (
            $Name
        )

        Get-ChildItem -Path 'tests\' -Recurse -Include "$Name.Tests.ps1" | Should -Not -BeNullOrEmpty
    }

    It 'Should pass Script Analyzer for <Name>' -TestCases $testCases -Skip:(-not $scriptAnalyzerRules) {
        param
        (
            $Name
        )

        $functionFile = Get-ChildItem -Path $sourcePath -Recurse -Include "$Name.ps1"

        $pssaResult = (Invoke-ScriptAnalyzer -Path $functionFile.FullName)
        $report = $pssaResult | Format-Table -AutoSize | Out-String -Width 110
        $pssaResult  | Should -BeNullOrEmpty -Because `
            "some rule triggered.`r`n`r`n $report"
    }
}

Describe 'Help for module' -Tags 'helpQuality' {
    It 'Should have .SYNOPSIS for <Name>' -TestCases $testCases {
        param
        (
            $Name
        )

        $functionFile = Get-ChildItem -Path $sourcePath -Recurse -Include "$Name.ps1"

        $scriptFileRawContent = Get-Content -Raw -Path $functionFile.FullName

        $abstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput($scriptFileRawContent, [ref] $null, [ref] $null)

        $astSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }

        $parsedFunction = $abstractSyntaxTree.FindAll( $astSearchDelegate, $true ) |
            Where-Object -FilterScript {
                $_.Name -eq $Name
            }

        $functionHelp = $parsedFunction.GetHelpContent()

        $functionHelp.Synopsis | Should -Not -BeNullOrEmpty
    }

    It 'Should have a .DESCRIPTION with length greater than 40 characters for <Name>' -TestCases $testCases {
        param
        (
            $Name
        )

        $functionFile = Get-ChildItem -Path $sourcePath -Recurse -Include "$Name.ps1"

        $scriptFileRawContent = Get-Content -Raw -Path $functionFile.FullName

        $abstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput($scriptFileRawContent, [ref] $null, [ref] $null)

        $astSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }

        $parsedFunction = $abstractSyntaxTree.FindAll( $astSearchDelegate, $true ) |
            Where-Object -FilterScript {
                $_.Name -eq $Name
            }

        $functionHelp = $parsedFunction.GetHelpContent()

        $functionHelp.Description.Length | Should -BeGreaterThan 40
    }

    It 'Should have at least one (1) example for <Name>' -TestCases $testCases {
        param
        (
            $Name
        )

        $functionFile = Get-ChildItem -Path $sourcePath -Recurse -Include "$Name.ps1"

        $scriptFileRawContent = Get-Content -Raw -Path $functionFile.FullName

        $abstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput($scriptFileRawContent, [ref] $null, [ref] $null)

        $astSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }

        $parsedFunction = $abstractSyntaxTree.FindAll( $astSearchDelegate, $true ) |
            Where-Object -FilterScript {
                $_.Name -eq $Name
            }

        $functionHelp = $parsedFunction.GetHelpContent()

        $functionHelp.Examples.Count | Should -BeGreaterThan 0
        $functionHelp.Examples[0] | Should -Match ([regex]::Escape($Name))
        $functionHelp.Examples[0].Length | Should -BeGreaterThan ($Name.Length + 10)
    }

    It 'Should have described all parameters for <Name>' -TestCases $testCases {
        param
        (
            $Name
        )

        $functionFile = Get-ChildItem -Path $sourcePath -Recurse -Include "$Name.ps1"

        $scriptFileRawContent = Get-Content -Raw -Path $functionFile.FullName

        $abstractSyntaxTree = [System.Management.Automation.Language.Parser]::ParseInput($scriptFileRawContent, [ref] $null, [ref] $null)

        $astSearchDelegate = { $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }

        $parsedFunction = $abstractSyntaxTree.FindAll( $astSearchDelegate, $true ) |
            Where-Object -FilterScript {
                $_.Name -eq $Name
            }

        $functionHelp = $parsedFunction.GetHelpContent()

        $parameters = $parsedFunction.Body.ParamBlock.Parameters.Name.VariablePath.ForEach({ $_.ToString() })

        foreach ($parameter in $parameters)
        {
            $functionHelp.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty -Because ('the parameter {0} must have a description' -f $parameter)
            $functionHelp.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 25 -Because ('the parameter {0} must have descriptive description' -f $parameter)
        }
    }
}
