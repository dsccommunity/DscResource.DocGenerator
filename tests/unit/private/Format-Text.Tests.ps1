#region HEADER
$script:projectPath = "$PSScriptRoot\..\..\.." | Convert-Path
$script:projectName = (Get-ChildItem -Path "$script:projectPath\*\*.psd1" | Where-Object -FilterScript {
        ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
        $(try
            {
                Test-ModuleManifest -Path $_.FullName -ErrorAction Stop
            }
            catch
            {
                $false
            })
    }).BaseName

$script:moduleName = Get-Module -Name $script:projectName -ListAvailable | Select-Object -First 1
Remove-Module -Name $script:moduleName -Force -ErrorAction 'SilentlyContinue'

Import-Module $script:moduleName -Force -ErrorAction 'Stop'
#endregion HEADER

InModuleScope $script:moduleName {
    Describe 'Format-Text' {
        It 'Should remove multiple whitespace and blank rows at end' {
            $formatTextParameters = @{
                Text = "My  text  with multiple    whitespace`r`n`r`n`r`n"
                Format = @(
                    'Replace_Multiple_Whitespace_With_One'
                    'Remove_Blank_Rows_At_End_Of_String'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly 'My text with multiple whitespace'
        }

        It 'Should remove indentations from blank rows when using CRLF' {
            $formatTextParameters = @{
                Text = "First line`r`n`u{20}`u{20}`r`nSecond line"
                Format = @(
                    'Remove_Indentation_From_Blank_Rows'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly "First line`r`n`r`nSecond line"
        }

        It 'Should remove indentations from blank rows when using LF' {
            $formatTextParameters = @{
                Text = "First line`n`u{20}`u{20}`nSecond line"
                Format = @(
                    'Remove_Indentation_From_Blank_Rows'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly @"
First line`n`nSecond line
"@
        }

        It 'Should remove indentations from blank rows when using both LF and CRLF' {
            $formatTextParameters = @{
                Text = "First line`n`u{20}`u{20}`n`u{20}`u{20}`r`nSecond line"
                Format = @(
                    'Remove_Indentation_From_Blank_Rows'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly "First line`n`n`r`nSecond line"
        }

        It 'Should replace CRLF with one whitespace' {
            $formatTextParameters = @{
                Text = "First line`r`nSecond line"
                Format = @(
                    'Replace_NewLine_With_One_Whitespace'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly 'First line Second line'
        }

        It 'Should replace LF with one whitespace' {
            $formatTextParameters = @{
                Text = "First line`nSecond line"
                Format = @(
                    'Replace_NewLine_With_One_Whitespace'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly 'First line Second line'
        }

        It 'Should replace vertical bar with one whitespace' {
            $formatTextParameters = @{
                Text = 'First|Second'
                Format = @(
                    'Replace_Vertical_Bar_With_One_Whitespace'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly 'First Second'
        }

        It 'Should remove whitespace from end of string' {
            $formatTextParameters = @{
                Text = 'First line  '
                Format = @(
                    'Remove_Whitespace_From_End_Of_String'
                )
            }

            $result = Format-Text @formatTextParameters

            $result | Should -BeExactly 'First line'
        }
    }
}
