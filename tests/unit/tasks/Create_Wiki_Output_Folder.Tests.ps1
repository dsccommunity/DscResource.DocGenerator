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

Describe 'Create_Wiki_Output_Folder' {
    BeforeAll {
        Mock -CommandName New-Item


        Mock -CommandName Test-Path -MockWith {
            return $false
        } -ParameterFilter {
            $Path -eq $wikiOutputPath
        }
    }

    It 'Should export the build script alias' {
        $buildTaskName = 'Create_Wiki_Output_Folder'
        $buildScriptAliasName = 'Task.{0}' -f $buildTaskName

        $script:buildScript = Get-Command -Name $buildScriptAliasName -Module $script:projectName

        $script:buildScript.Name | Should -Be $buildScriptAliasName
        $script:buildScript.ReferencedCommand | Should -Be ('{0}.build.ps1' -f $buildTaskName)
    }

    It 'Should reference an existing build script' {
        Test-Path -Path $script:buildScript.Definition | Should -BeTrue
    }

    It 'Should run the build task without throwing' {
        {
            $taskParameters = @{
                ProjectName = 'DscResource.DocGenerator'
                SourcePath = $TestDrive
            }

            Invoke-Build -Task $buildTaskName -File $script:buildScript.Definition @taskParameters
        } | Should -Not -Throw

        Assert-MockCalled -CommandName New-Item -Exactly -Times 1 -Scope It
    }
}
