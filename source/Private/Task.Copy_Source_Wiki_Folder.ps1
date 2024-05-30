<#
    .SYNOPSIS
        This is the alias to the build task Copy_Source_Wiki_Folder's script file.

    .DESCRIPTION
        This makes available the alias 'Task.Copy_Source_Wiki_Folder' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Copy_Source_Wiki_Folder' -Value "$PSScriptRoot/tasks/Copy_Source_Wiki_Folder.build.ps1"
