<#
    .SYNOPSIS
        Formats a string using predefined format options.

    .DESCRIPTION
        Formats a string using predefined format options.

    .PARAMETER Text
        Specifies the string to format.

    .PARAMETER Format
        One or more predefined format options. The formatting is done in the
        provided order.

    .EXAMPLE
        Format-Text -Text 'My  text  description' -Format @('Replace_Multiple_Whitespace_With_One')

        Returns a string correctly formatted with one whitespace between each word.
#>
function Format-Text
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Text,

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            'Replace_Multiple_Whitespace_With_One',
            'Remove_Blank_Rows_At_End_Of_String',
            'Remove_Indentation_From_Blank_Rows',
            'Replace_NewLine_With_One_Whitespace',
            'Replace_Vertical_Bar_With_One_Whitespace',
            'Remove_Whitespace_From_End_Of_String'
        )]
        [System.String[]]
        $Format
    )

    $returnString = $Text

    switch ($Format)
    {
        # Replace multiple whitespace with one single white space
        'Replace_Multiple_Whitespace_With_One'
        {
            $returnString = $returnString -replace '  +', ' '
        }

        # Removes all blank rows at the end
        'Remove_Blank_Rows_At_End_Of_String'
        {
            $returnString = $returnString -replace '[\r?\n]+$'
        }

        # Remove all indentations from blank rows
        'Remove_Indentation_From_Blank_Rows'
        {
            $returnString = $returnString -replace '[ ]+\r\n', "`r`n"
            $returnString = $returnString -replace '[ ]+\n', "`n"
        }

        # Replace LF or CRLF with one white space
        'Replace_NewLine_With_One_Whitespace'
        {
            $returnString = $returnString -replace '\r?\n', ' '
        }

        # Replace vertical bar with one white space
        'Replace_Vertical_Bar_With_One_Whitespace'
        {
            $returnString = $returnString -replace '\|', ' '
        }

        # Remove white space from end of string
        'Remove_Whitespace_From_End_Of_String'
        {
            $returnString = $returnString -replace ' +$'
        }
    }

    return $returnString
}
