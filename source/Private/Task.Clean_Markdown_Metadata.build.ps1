<#
    .SYNOPSIS
        This is the alias to the build task Clean_Markdown_Metadata script file.

    .DESCRIPTION
        This makes available the alias 'Task.Clean_Markdown_Metadata' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Clean_Markdown_Metadata' -Value "$PSScriptRoot/tasks/Clean_Markdown_Metadata.build.ps1"
