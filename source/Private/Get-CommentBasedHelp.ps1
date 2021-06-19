<#
    .SYNOPSIS
        Get-CommentBasedHelp returns comment-based help from a PowerShell
        script file.

    .DESCRIPTION
        Get-CommentBasedHelp returns comment-based help for a PowerShell script
        file by parsing the source PowerShell script file. If the comment block
        is not the first element in the file then the first comment block will
        be located and everything before it will be removed before parsing.

    .PARAMETER Path
        The path to the PowerShell script file. This should be a
        PowerShell script file that contains one resource with the
        comment-based help at the top of the file.

    .OUTPUTS
        System.Management.Automation.Language.CommentHelpInfo

    .EXAMPLE
        $commentBasedHelp = Get-CommentBasedHelp -Path 'c:\MyProject\source\Classes\010-MyResourceName.ps1'

        This example parses the comment-based help from the PowerShell script file
        'c:\MyProject\source\Classes\010-MyResourceName.ps1' and returns an
        object of System.Management.Automation.Language.CommentHelpInfo.

    .NOTES
        PowerShell classes do not support comment-based help. There is
        no GetHelpContent() on the TypeDefinitionAst.

        We use the ScriptBlockAst to filter out our class-based resource
        script block from the source file and use that to get the
        comment-based help.
#>
function Get-CommentBasedHelp
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommentHelpInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    $Path = Resolve-Path -Path $Path

    Write-Verbose -Message ($script:localizedData.CommentBasedHelpMessage -f $Path)

    $scriptContent = Get-Content -Path $Path -Raw

    # Ensure the comment-based help block is at the top of the file.
    $regexOptions = [System.Text.RegularExpressions.RegexOptions]::Multiline
    $firstCommentBlockStart = [System.Text.RegularExpressions.Regex]::Match($scriptContent, "^<#(\n|\r|\r\n)$", $regexOptions)

    if ($firstCommentBlockStart.Success)
    {
        Write-Verbose -Message ($script:localizedData.CommentBasedHelpBlockNotAtTopMessage -f $Path)
        $scriptContent = $scriptContent.Substring($firstCommentBlockStart.Index)
    }
    else
    {
        Write-Warning -Message (
            $script:localizedData.CommentBasedHelpBlockNotFound -f $Path
        )
    }

    $tokens, $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref] $tokens, [ref] $parseErrors)

    if ($parseErrors)
    {
        <#
            Normally we should throw if there is any parse errors but in the case
            of the class-based resource source file that is not possible. If the
            class is inheriting from a base class that base class is not part of
            the source script file which will generate a parse error.
            Even with parse errors the comment-based help is available with
            GetHelpContent(). The errors are outputted for debug purposes, if there
            would be a future problem that we have not taken account for.
        #>
        Write-Debug -Message (
            $script:localizedData.IgnoreAstParseErrorMessage -f ($parseErrors | Out-String)
        )
    }

    $dscResourceCommentBasedHelp = $ast.GetHelpContent()

    return $dscResourceCommentBasedHelp
}
