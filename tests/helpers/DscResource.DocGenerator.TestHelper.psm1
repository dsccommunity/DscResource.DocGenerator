<#
        .SYNOPSIS
            This output two text blocks side-by-side in hex to easily
            compare the diff.
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

    Write-Verbose -Message 'ERROR: Wrong output generated:' -Verbose

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
