
<#
    .SYNOPSIS
        Creates a GitHub Wiki sidebar based on existing markdown files and their metadata.

    .DESCRIPTION
        This command creates a new GitHub wiki sidebar file with the specified output
        path and sidebar file name. The sidebar is created based on existing markdown
        files and their metadata

    .PARAMETER DocumentationPath
        Specifies the FileInfo object of the markdown file containing the documentation
        being edited. This parameter is mandatory.

    .PARAMETER OutputPath
        Specifies the output path where the sidebar file will be created.

    .PARAMETER SidebarFileName
        Specifies the name of the sidebar file. The default value is '_Sidebar.md'.

    .PARAMETER ReplaceExisting
        Specifies whether to force the creation of the sidebar even if it already exists.
        By default, if the sidebar file already exists, the function will not overwrite it.

    .PARAMETER Force
        Specifies that the sidebar should be created without any confirmation.

    .EXAMPLE
        New-GitHubWikiSidebar -OutputPath 'C:\Wiki' -SidebarFileName 'CustomSidebar.md'

        Creates a new GitHub wiki sidebar file named 'CustomSidebar.md' in the 'C:\Wiki'
        directory.

    .EXAMPLE
        New-GitHubWikiSidebar -DocumentationPath './output/WikiOutput' -Force

        Creates a GitHub Wiki sidebar using default path and filename. The sidebar
        will be created even if it already exists.
#>
function New-GitHubWikiSidebar
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [System.String]
        $DocumentationPath,

        [Parameter()]
        [ValidateScript({Test-Path $_ -PathType 'Container'})]
        [System.String]
        $OutputPath,

        [Parameter()]
        [System.String]
        $SidebarFileName = '_Sidebar.md',

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $ReplaceExisting,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force
    )

    if ($Force.IsPresent -and -not $Confirm)
    {
        $ConfirmPreference = 'None'
    }

    if (-not $OutputPath)
    {
        $OutputPath = $DocumentationPath
    }

    $sidebarFilePath = Join-Path -Path $OutputPath -ChildPath $SidebarFileName

    <#
        If the sidebar file already exists, don't overwrite it unless the -Force
        parameter is used. This is to prevent overwriting if there are already a
        sidebar that was created or copied to WikiOutput by another task, e.g.
        Generate_Wiki_Content that copies the content of the WikiSource folder
        to WikiOutput.
    #>
    if (-not $ReplaceExisting -and (Test-Path -Path $sidebarFilePath))
    {
        Write-Warning "Sidebar file '$sidebarFilePath' already exists. Leaving it unchanged. Use -ReplaceExisting to overwrite."

        return
    }

    $verboseDescriptionMessage = $script:localizedData.NewGitHubWikiSidebar_ShouldProcessVerboseDescription -f $sidebarFilePath
    $verboseWarningMessage = $script:localizedData.NewGitHubWikiSidebar_ShouldProcessVerboseWarning -f $sidebarFilePath, $DocumentationPath
    $captionMessage = $script:localizedData.NewGitHubWikiSidebar_ShouldProcessCaption

    if (-not $PSCmdlet.ShouldProcess($verboseDescriptionMessage, $verboseWarningMessage, $captionMessage))
    {
        return
    }

    # cSpell: disable-next-line
    $markdownFiles = Get-ChildItem -Path "$DocumentationPath/*.md" -Exclude @('_[Ss]idebar.md', '_[Ff]ooter.md')

    $sidebarCategories = @{}

    foreach ($file in $markdownFiles)
    {
        Write-Debug -Message "Processing file '$($file.FullName)'."

        $getMarkdownMetadataScript = @"
Get-MarkdownMetadata -Path $($file.FullName) -ErrorAction 'Stop'
"@

        Write-Debug -Message $getMarkdownMetadataScript

        $getMarkdownMetadataScriptBlock = [ScriptBlock]::Create($getMarkdownMetadataScript)

        $pwshPath = (Get-Process -Id $PID).Path

        <#
            The scriptblock is run in a separate process to avoid conflicts with
            other modules that are loaded in the current process.
        #>
        $markdownMetadata = & $pwshPath -Command $getMarkdownMetadataScriptBlock -ExecutionPolicy 'ByPass' -NoProfile

        # If the category doesn't exist in the metadata, add it to the default category General.
        if (-not $markdownMetadata -or -not $markdownMetadata.ContainsKey('Category'))
        {
            $markdownMetadata = @{
                Category = 'General'
            }
        }

        Write-Information -MessageData "Found documentation '$($file.BaseName)' of type '$($markdownMetadata.Type)' in category '$($markdownMetadata.Category)'." -InformationAction 'Continue'

        if (-not $sidebarCategories.ContainsKey($markdownMetadata.Category))
        {
            $sidebarCategories[$markdownMetadata.Category] = @()
        }

        $sidebarCategories[$markdownMetadata.Category] += $file.BaseName
    }

    $output = New-Object -TypeName 'System.Text.StringBuilder'

    # Always put link to Home at the top of the file.
    if ($sidebarCategories.ContainsKey('General'))
    {
        if ($sidebarCategories.General -contains 'Home')
        {
            $null = $output.AppendLine('[Home](Home)')
            $null = $output.AppendLine()
        }
    }

    # Always put category General at the top of the list.
    if ($sidebarCategories.ContainsKey('General'))
    {
        $sortedListItem = $sidebarCategories.General |
            Where-Object -FilterScript {
                $_ -ne 'Home'
            } | Sort-Object

        if ($sortedListItem.Count -gt 0)
        {
            $null = $output.AppendLine('### General')
            $null = $output.AppendLine()

            foreach ($link in $sortedListItem)
            {
                $null = $output.AppendLine('- [' + $link + '](' + $link + ')')
            }

            $null = $output.AppendLine()
        }
    }

    $sortedCategories = $sidebarCategories.Keys |
        Where-Object -FilterScript {
            $_ -ne 'General'
        } | Sort-Object

    foreach ($category in $sortedCategories)
    {
        $null = $output.AppendLine("### $category")
        $null = $output.AppendLine()

        foreach ($link in $sidebarCategories.$category | Sort-Object)
        {
            $null = $output.AppendLine('- [' + $link + '](' + $link + ')')
        }

        $null = $output.AppendLine()
    }

    $outputToWrite = $output.ToString()
    $outputToWrite = $outputToWrite -replace '[\r|\n]+$' # Removes all blank rows and whitespace at the end
    $outputToWrite = $outputToWrite -replace '\r?\n', "`r`n" # Normalize to CRLF
    $outputToWrite = $outputToWrite -replace '[ ]+\r\n', "`r`n" # Remove indentation from blank rows

    $outFileParameters = @{
        InputObject = $outputToWrite
        FilePath = $sidebarFilePath
        Force = $ReplaceExisting
    }

    if ($PSVersionTable.PSVersion -lt '6.0')
    {
        $outFileParameters.Encoding = 'UTF8'
    }
    else
    {
        $outFileParameters.Encoding = [System.Text.Encoding]::UTF8
    }

    $null = Out-File @outFileParameters
}
