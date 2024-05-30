<#
    .SYNOPSIS
        This is the alias to the build task Create_Wiki_Output_Folder's script file.

    .DESCRIPTION
        This makes available the alias 'Task.Create_Wiki_Output_Folder' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Create_Wiki_Output_Folder' -Value "$PSScriptRoot/tasks/Create_Wiki_Output_Folder.build.ps1"
