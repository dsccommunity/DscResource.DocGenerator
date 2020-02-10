<#
    .SYNOPSIS
        This is the alias to the build task Generate_Conceptual_Help's script file.

    .DESCRIPTION
        This make available the alias 'Task.Generate_Conceptual_Help' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Generate_Conceptual_Help' -Value "$PSScriptRoot/tasks/Generate_Conceptual_Help.build.ps1"
