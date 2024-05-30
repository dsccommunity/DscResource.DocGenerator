<#
    .SYNOPSIS
        This is the alias to the build task Generate_Markdown_For_DSC_Resources's script file.

    .DESCRIPTION
        This makes available the alias 'Task.Generate_Markdown_For_DSC_Resources' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Generate_Markdown_For_DSC_Resources' -Value "$PSScriptRoot/tasks/Generate_Markdown_For_DSC_Resources.build.ps1"
