<#
    .SYNOPSIS
        Get-ClassResourceCommentBasedHelp returns comment-based help for a DSC resource.

    .DESCRIPTION
        Get-ClassResourceCommentBasedHelp returns comment-based help for a DSC resource
        by parsing the source PowerShell script file.

    .PARAMETER Path
        The path to the DSC resource PowerShell script file. This should be a
        PowerShell script file that only contain one resource with the
        comment-based help at the top of the file.

    .OUTPUTS
        System.Management.Automation.Language.CommentHelpInfo

    .EXAMPLE
        $commentBasedHelp = Get-ClassResourceCommentBasedHelp -Path 'c:\MyProject\source\Classes\010-MyResourceName.ps1'

        This example parses the comment-based help from the PowerShell script file
        'c:\MyProject\source\Classes\010-MyResourceName.ps1' and returns an
        object of System.Management.Automation.Language.CommentHelpInfo.
#>
function Get-ClassResourceCommentBasedHelp
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.Language.CommentHelpInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Path
    )

    <#
        PowerShell classes does not support comment-based help. There is
        no GetHelpContent() on the TypeDefinitionAst.

        We use the ScriptBlockAst to filter out our class-based resource
        script block from the source file and use that to get the
        comment-based help.
    #>
    $Path = Resolve-Path -Path $Path

    Write-Verbose -Message ($script:localizedData.ClassBasedCommentBasedHelpMessage -f $Path)

    $tokens, $parseErrors = $null

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref] $tokens, [ref] $parseErrors)

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
