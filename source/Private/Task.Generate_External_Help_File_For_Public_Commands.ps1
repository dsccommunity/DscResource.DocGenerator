<#
    .SYNOPSIS
        This is the alias to the build task Generate_External_Help_File_For_Public_Commands script file.

    .DESCRIPTION
        This makes available the alias 'Task.Generate_External_Help_File_For_Public_Commands' that is
        exported in the module manifest so that the build task can be correctly
        imported using for example Invoke-Build.

    .NOTES
        This is using the pattern lined out in the Invoke-Build repository
        https://github.com/nightroman/Invoke-Build/tree/master/Tasks/Import.
#>

Set-Alias -Name 'Task.Generate_External_Help_File_For_Public_Commands' -Value "$PSScriptRoot/tasks/Generate_External_Help_File_For_Public_Commands.build.ps1"
