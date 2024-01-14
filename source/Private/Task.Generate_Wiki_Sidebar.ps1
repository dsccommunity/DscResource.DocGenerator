<#
    .SYNOPSIS
        This is the alias to the build task Generate_Wiki_Sidebar's script file.

    .DESCRIPTION
        This makes available the alias 'Task.Generate_Wiki_Sidebar' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Generate_Wiki_Sidebar' -Value "$PSScriptRoot/tasks/Generate_Wiki_Sidebar.build.ps1"
