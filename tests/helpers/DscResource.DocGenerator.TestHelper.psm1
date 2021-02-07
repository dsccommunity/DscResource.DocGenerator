<#
    .SYNOPSIS
        This output two text blocks side-by-side in hex to easily
        compare the diff.

    .DESCRIPTION
        This output two text blocks side-by-side in hex to easily
        compare the diff. It is main intended use is as a helper for unit test
        when comparing large text mass which can have small normally invisible
        difference like an extra pch missing LF.

    .PARAMETER Actual
        A text string that should be compared against the text string that is passed
        in parameter 'Expected'.

    .PARAMETER Expected
        A text string that should be compared against the text string that is passed
        in parameter 'Actual'.

    .EXAMPLE
        Out-Diff `
            -Expected 'This is a longer text string that was expected to be shown' `
            -Actual 'This is the actual text string'

    .NOTES
        This outputs the lines in verbose statements because it is the easiest way
        to show output when running tests in Pester. The output is wide, 185 characters,
        to get the best side-by-side comparison.
#>
function Out-Diff
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $Actual,

        [Parameter()]
        [System.String]
        $Expected
    )

    Write-Verbose -Message 'UNEXPECTED RESULT GENERATED:' -Verbose

    $expectedHex = $Expected | Format-Hex
    $actualHex = $Actual | Format-Hex

    $maxLength = @($expectedHex.length, $actualHex.length) |
        Measure-Object -Maximum |
        Select-Object -ExpandProperty 'Maximum'

    $column1Width = ($expectedHex[0] -replace '\r?\n').Length

    Write-Verbose -Message ("Expected:{0}But was:" -f ''.PadRight($column1Width - 1)) -Verbose

    # Remove one since we start at 0.
    $maxLength -= 1

    0..$maxLength | ForEach-Object -Process {
        $expectedRow = $expectedHex[$_] -replace '\r?\n'
        $actualRow = $actualHex[$_] -replace '\r?\n'

        # Handle if expected is shorter than actual
        if (-not $expectedRow)
        {
            $expectedRow = ''.PadRight($column1Width)
        }

        $diffIndicator = '  '

        if ($expectedRow -ne $actualRow)
        {
            $diffIndicator = '!='
        }

        Write-Verbose -Message ("{0}   {1}   {2}" -f $expectedRow, $diffIndicator, $actualRow) -Verbose
    }
}
