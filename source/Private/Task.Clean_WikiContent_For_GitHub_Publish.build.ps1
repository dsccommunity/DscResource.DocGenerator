<#
    .SYNOPSIS
        This is the alias to the build task Clean_WikiContent_For_GitHub_Publish
        script file.

    .DESCRIPTION
        This makes available the alias 'Task.Clean_WikiContent_For_GitHub_Publish'
        that is exported in the module manifest so that the build task can be
        correctly imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Clean_WikiContent_For_GitHub_Publish' -Value "$PSScriptRoot/tasks/Clean_WikiContent_For_GitHub_Publish.build.ps1"
