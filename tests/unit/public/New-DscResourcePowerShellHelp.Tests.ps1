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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath '../../helpers/DscResource.DocGenerator.TestHelper.psm1') -Force

InModuleScope $script:moduleName {
    <#
        .NOTES
            This stub function is created because when original Out-File is
            mocked in PowerShell 6.x it changes the type of the Encoding
            parameter to [System.Text.Encoding] which when called with
            `OutFile -Encoding 'ascii'` fails with the error message
            "Cannot process argument transformation on parameter 'Encoding'.
            Cannot convert the "ascii" value of type "System.String" to type
            "System.Text.Encoding".
    #>
    function Out-File
    {
        [CmdletBinding()]
        param
        (
            [Parameter(ValueFromPipeline = $true)]
            [System.String]
            $InputObject,

            [Parameter()]
            [System.String]
            $FilePath,

            [Parameter()]
            [System.String]
            $Encoding,

            [Parameter()]
            [Switch]
            $NoNewLine,

            [Parameter()]
            [System.Management.Automation.SwitchParameter]
            $Force
        )

        throw 'StubNotImplemented'
    }

    Describe 'New-DscResourcePowerShellHelp' {
        Context 'When generating documentation for MOF-based resources' {
            $script:mockOutputPath = Join-Path -Path $TestDrive -ChildPath 'docs'
            $script:mockDestinationModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyModule\1.0.0'
            $script:mockModulePath = Join-Path -Path $TestDrive -ChildPath 'module'

            # Schema file info
            $script:mockResourceName = 'MyResource'
            $script:expectedSchemaPath = Join-Path -Path $script:mockModulePath -ChildPath '\**\*.schema.mof'
            $script:mockSchemaBaseName = "MSFT_$($script:mockResourceName).schema"
            $script:mockSchemaFileName = "$($script:mockSchemaBaseName).mof"
            $script:mockSchemaFolder = Join-Path -Path $script:mockModulePath -ChildPath "DSCResources\$($script:mockResourceName)"
            $script:mockSchemaFilePath = Join-Path -Path $script:mockSchemaFolder -ChildPath $script:mockSchemaFileName
            $script:mockSchemaFiles = @(
                @{
                    FullName      = $script:mockSchemaFilePath
                    Name          = $script:mockSchemaFileName
                    DirectoryName = $script:mockSchemaFolder
                    BaseName      = $script:mockSchemaBaseName
                }
            )
            $script:mockGetMofSchemaObject = @{
                ClassName    = 'MSFT_MyResource'
                Attributes   = @(
                    @{
                        State            = 'Key'
                        DataType         = 'String'
                        ValueMap         = @()
                        IsArray          = $false
                        Name             = 'Id'
                        Description      = 'Id Description'
                        EmbeddedInstance = ''
                    },
                    @{
                        State            = 'Write'
                        DataType         = 'String'
                        ValueMap         = @( 'Value1', 'Value2', 'Value3' )
                        IsArray          = $false
                        Name             = 'Enum'
                        Description      = 'Enum Description. Test inline code-block `$true`.'
                        EmbeddedInstance = ''
                    },
                    @{
                        State            = 'Required'
                        DataType         = 'Uint32'
                        ValueMap         = @()
                        IsArray          = $false
                        Name             = 'Int'
                        Description      = 'Int Description.'
                        EmbeddedInstance = ''
                    },
                    @{
                        State            = 'Read'
                        DataType         = 'String'
                        ValueMap         = @()
                        IsArray          = $false
                        Name             = 'Read'
                        Description      = 'Read Description.'
                        EmbeddedInstance = ''
                    }
                )
                ClassVersion = '1.0.0'
                FriendlyName = 'MyResource'
            }

            # Example file info
            $script:mockExampleFilePath = Join-Path -Path $script:mockModulePath -ChildPath "\Examples\Resources\$($script:mockResourceName)\$($script:mockResourceName)_Example1_Config.ps1"
            $script:expectedExamplePath = Join-Path -Path $script:mockModulePath -ChildPath "\Examples\Resources\$($script:mockResourceName)\*.ps1"
            $script:mockExampleFiles = @(
                @{
                    Name      = "$($script:mockResourceName)_Example1_Config.ps1"
                    FullName  = $script:mockExampleFilePath
                }
            )

            $script:mockExampleContent = '.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyResource Something
        {
            Id    = ''MyId''
            Enum  = ''Value1''
            Int   = 1
        }
    }
}' -replace '\r?\n', "`r`n"

            # General mock values
            $script:mockReadmePath = $script:mockSchemaFolder
            $script:mockOutputFile = Join-Path -Path $script:mockOutputPath -ChildPath "$($script:mockResourceName).md"
            $script:mockSavePath = Join-Path -Path $script:mockModulePath -ChildPath "DscResources\$($script:mockResourceName)\en-US\about_$($script:mockResourceName).help.txt"
            $script:mockOutputSavePath = Join-Path -Path $script:mockOutputPath -ChildPath "about_$($script:mockResourceName).help.txt"
            $script:mockDestinationModulePathSavePath = Join-Path -Path $script:mockDestinationModulePath -ChildPath "DscResources\$($script:mockResourceName)\en-US\about_$($script:mockResourceName).help.txt"
            $script:mockGetContentReadme = '# Description

The description of the _resource_.
Second row of description.
' -replace '\r?\n', "`r`n"

            $script:mockPowerShellHelpOutput = '.NAME
    MyResource

.DESCRIPTION
    The description of the _resource_.
    Second row of description.

.PARAMETER Id
    Key - String
    Id Description

.PARAMETER Enum
    Write - String
    Allowed values: Value1, Value2, Value3
    Enum Description. Test inline code-block `$true`.

.PARAMETER Int
    Required - Uint32
    Int Description.

.PARAMETER Read
    Read - String
    Read Description.

.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyResource Something
        {
            Id    = ''MyId''
            Enum  = ''Value1''
            Int   = 1
        }
    }
}
' -replace '\r?\n', "`r`n"

            # Parameter filters
            $script:getChildItemSchema_parameterFilter = {
                $Path -eq $script:expectedSchemaPath
            }

            $script:getChildItemExample_parameterFilter = {
                $Path -eq $script:expectedExamplePath
            }

            $script:getMofSchemaObjectSchema_parameterFilter = {
                $Filename -eq $script:mockSchemaFilePath
            }

            $script:getChildItemReadme_parameterFilter = {
                $Path -eq $script:mockReadmePath
            }

            $script:getContentReadme_parameterFilter = {
                $Path -eq (Join-Path -Path $script:mockReadmePath -ChildPath 'README.md')
            }

            $script:getDscResourceHelpExampleContent_parameterFilter = {
                $ExamplePath -eq $script:mockExampleFilePath -and $ExampleNumber -eq 1
            }

            $script:outFile_parameterFilter = {
                $FilePath -eq $script:mockSavePath
            }

            $script:outFileContent_parameterFilter = {
                if ($InputObject -ne $script:mockPowerShellHelpOutput)
                {
                    # Helper to output the diff.
                    Out-Diff -Actual $InputObject -Expected $script:mockPowerShellHelpOutput
                }

                $InputObject -eq $script:mockPowerShellHelpOutput
            }

            $script:outFileOutputInputObject_parameterFilter = {
                $FilePath -eq $script:mockOutputSavePath
            }

            $script:outFileDestinationModulePathInputObject_parameterFilter = {
                $InputObject -eq $script:mockPowerShellHelpOutput -and
                $FilePath -eq $script:mockDestinationModulePathSavePath
            }

            $script:writeWarningDescription_parameterFilter = {
                $Message -eq ($script:localizedData.NoDescriptionFileFoundWarning -f $script:mockResourceName)
            }

            $script:writeWarningExample_parameterFilter = {
                $Message -eq ($script:localizedData.NoExampleFileFoundWarning -f $script:mockResourceName)
            }

            # Function call parameters
            $script:newDscResourcePowerShellHelp_parameters = @{
                ModulePath = $script:mockModulePath
                Verbose = $true
            }

            $script:newDscResourcePowerShellHelpOutput_parameters = @{
                ModulePath = $script:mockModulePath
                OutputPath = $script:mockOutputPath
                Verbose = $true
            }

            $script:newDscResourcePowerShellHelpDestinationModulePath_parameters = @{
                ModulePath = $script:mockModulePath
                DestinationModulePath = $script:mockDestinationModulePath
                Verbose = $true
            }

            Context 'When there is no schemas found in the module folder' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourcePowerShellHelp @script:newDscResourcePowerShellHelp_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    <#
                        Regression test for issue https://github.com/dsccommunity/DscResource.DocGenerator/issues/55.
                        When parameter File is present the command Get-ChildItem
                        returns 0 (zero) files.
                    #>
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter {
                            $PSBoundParameters.ContainsKey('File') -eq $false
                        } `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -Exactly -Times 0
                }
            }

            Context 'When there is no resource description found' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourcePowerShellHelp @script:newDscResourcePowerShellHelp_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter `
                        -Exactly -Times 0
                }
            }

            Context 'When there is no resource example file found' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -MockWith {
                            return [PSCustomObject] @{
                                # This is intentionally using the upper-case 'README.md'.
                                Name = 'README.md'
                                FullName = Join-Path -Path $script:mockReadmePath -ChildPath 'README.md'
                            }
                        }

                    Mock `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -MockWith { $script:mockGetContentReadme }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter

                    Mock `
                        -CommandName Get-DscResourceHelpExampleContent

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourcePowerShellHelp @script:newDscResourcePowerShellHelp_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter `
                        -Exactly -Times 0
                }
            }

            Context 'When there is one schema found in the module folder and one example using .EXAMPLE and the OutputPath is specified' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -MockWith {
                            return [PSCustomObject] @{
                                # This is intentionally using the upper-case 'README.md'.
                                Name = 'README.md'
                                FullName = Join-Path -Path $script:mockReadmePath -ChildPath 'README.md'
                            }
                        }

                    Mock `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -MockWith { $script:mockGetContentReadme }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -MockWith { $script:mockExampleFiles }

                    Mock `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -MockWith { $script:mockExampleContent }

                    Mock `
                        -CommandName Out-File

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourcePowerShellHelp @script:newDscResourcePowerShellHelpOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileOutputInputObject_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_parameterFilter `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter `
                        -Exactly -Times 0
                }
            }

            Context 'When there is one schema found in the module folder and one example using .EXAMPLE and the DestinationModulePath is specified' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -MockWith {
                            return [PSCustomObject] @{
                                # This is intentionally using the upper-case 'README.md'.
                                Name = 'README.md'
                                FullName = Join-Path -Path $script:mockReadmePath -ChildPath 'README.md'
                            }
                        }

                    Mock `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -MockWith { $script:mockGetContentReadme }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -MockWith { $script:mockExampleFiles }

                    Mock `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -MockWith { $script:mockExampleContent }

                    Mock `
                        -CommandName Out-File

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourcePowerShellHelp @script:newDscResourcePowerShellHelpDestinationModulePath_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileDestinationModulePathInputObject_parameterFilter `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter `
                        -Exactly -Times 0
                }
            }

            Context 'When there is one schema found in the module folder and one example using .EXAMPLE and only the parameter ModulePath is specified' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -MockWith {
                            return [PSCustomObject] @{
                                # This is intentionally using the lower-case 'readme.md'.
                                Name = 'readme.md'
                                FullName = Join-Path -Path $script:mockReadmePath -ChildPath 'readme.md'
                            }
                        }

                    Mock `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -MockWith { $script:mockGetContentReadme }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -MockWith { $script:mockExampleFiles }

                    Mock `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -MockWith { $script:mockExampleContent }

                    Mock `
                        -CommandName Out-File

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourcePowerShellHelp @script:newDscResourcePowerShellHelp_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_parameterFilter `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter `
                        -Exactly -Times 0
                }
            }

            Context 'When markdown code should be remove from text.' {
                BeforeAll {
                    $mockExpectedFileOutput = '.NAME
    MyResource

.DESCRIPTION
    The description of the resource.
    Second row of description.

.PARAMETER Id
    Key - String
    Id Description

.PARAMETER Enum
    Write - String
    Allowed values: Value1, Value2, Value3
    Enum Description. Test inline code-block $true.

.PARAMETER Int
    Required - Uint32
    Int Description.

.PARAMETER Read
    Read - String
    Read Description.

.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyResource Something
        {
            Id    = ''MyId''
            Enum  = ''Value1''
            Int   = 1
        }
    }
}
' -replace '\r?\n', "`r`n"

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -MockWith {
                            return [PSCustomObject] @{
                                Name = 'README.md'
                                FullName = Join-Path -Path $script:mockReadmePath -ChildPath 'README.md'
                            }
                        }

                    Mock `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -MockWith { $script:mockGetContentReadme }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -MockWith { $script:mockExampleFiles }

                    Mock `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -MockWith { $script:mockExampleContent }

                    Mock `
                        -CommandName Out-File

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    {
                        New-DscResourcePowerShellHelp -MarkdownCodeRegularExpression @(
                            '\`(.+?)\`' # Match inline code-block
                            '_(.+?)_' # Match Italic (underscore)
                        ) @script:newDscResourcePowerShellHelpOutput_parameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter {
                            if ($InputObject -ne $mockExpectedFileOutput)
                            {
                                # Helper to output the diff.
                                Out-Diff -Expected $mockExpectedFileOutput -Actual $InputObject
                            }

                            $InputObject -eq $mockExpectedFileOutput
                        } -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-DscResourceHelpExampleContent `
                        -ParameterFilter $script:getDscResourceHelpExampleContent_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter `
                        -Exactly -Times 0

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter `
                        -Exactly -Times 0
                }
            }
        }

        Context 'When generating documentation for class-based resources' {
            BeforeAll {
                $mockDestinationModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'
                $mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'source'

                New-Item -Path $mockDestinationModulePath -ItemType 'Directory' -Force
                New-Item -Path "$mockSourcePath\Classes" -ItemType 'Directory' -Force
                New-Item -Path "$mockSourcePath\Examples\Resources\AzDevOpsProject" -ItemType 'Directory' -Force

                $mockExpectedFileOutput = ''

                $script:outFileContent_ParameterFilter = {
                    if ($InputObject -ne $mockExpectedFileOutput)
                    {
                        # Helper to output the diff.
                        Out-Diff -Expected $mockExpectedFileOutput -Actual $InputObject
                    }

                    $InputObject -eq $mockExpectedFileOutput
                }
            }

            Context 'When the resource is describe with just synopsis and one key property that does not have description' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockDestinationModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockSourceScript = @'
<#
    .SYNOPSIS
        A DSC Resource for Azure DevOps that
        represents the Project resource.

        This is another row.
#>
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
.NAME
    AzDevOpsProject

.SYNOPSIS
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.DESCRIPTION


.PARAMETER ProjectName
    Key - System.String

'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        ModulePath = $mockSourcePath
                        DestinationModulePath = $mockDestinationModulePath
                        Verbose = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }

                Context 'When the output should be written to the en-US folder in the DestinationModulePath' {
                    BeforeAll {
                        $mockFilePath = Join-Path -Path $mockDestinationModulePath -ChildPath 'en-US' |
                            Join-Path -ChildPath 'about_AzDevOpsProject.help.txt'

                        $mockNewDscResourcePowerShellHelpParameters = @{
                            ModulePath = $mockSourcePath
                            DestinationModulePath = $mockDestinationModulePath
                        }
                    }

                    It 'Should not throw an exception and call Out-File with the correct path' {
                        {
                            New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                        } | Should -Not -Throw

                        Assert-MockCalled -CommandName Out-File -ParameterFilter {
                            $FilePath -eq $mockFilePath
                        } -Exactly -Times 1 -Scope It
                    }
                }

                Context 'When the output should be written to the en-US folder in the OutputPath' {
                    BeforeAll {
                        $mockOutputPath = Join-Path -Path $TestDrive -ChildPath 'outputPath'
                        $mockFilePath = Join-Path -Path $mockOutputPath -ChildPath 'about_AzDevOpsProject.help.txt'

                        $mockNewDscResourcePowerShellHelpParameters = @{
                            ModulePath = $mockSourcePath
                            DestinationModulePath = $mockDestinationModulePath
                            OutputPath = $mockOutputPath
                        }
                    }

                    It 'Should not throw an exception and call Out-File with the correct path' {
                        {
                            New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                        } | Should -Not -Throw

                        Assert-MockCalled -CommandName Out-File -ParameterFilter {
                            $FilePath -eq $mockFilePath
                        } -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When the resource is describe with just description and one key property that does not have description' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockDestinationModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockSourceScript = @'
<#
    .DESCRIPTION
        A DSC Resource for Azure DevOps that
        represents the Project resource.

        This is another row.
#>
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
.NAME
    AzDevOpsProject

.SYNOPSIS


.DESCRIPTION
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.PARAMETER ProjectName
    Key - System.String

'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        ModulePath = $mockSourcePath
                        DestinationModulePath = $mockDestinationModulePath
                        Verbose = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the resource have one example' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockDestinationModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockSourceScript = @'
<#
    .DESCRIPTION
        A DSC Resource for Azure DevOps that
        represents the Project resource.

        This is another row.
#>
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockExampleScript = @'
<#
    .DESCRIPTION
        This example shows how to ensure that the Azure DevOps project
        called 'Test Project' exists (or is added if it does not exist).
#>
Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDevOpsProject 'AddProject'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
        }
    }
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockExampleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Examples\Resources\AzDevOpsProject\1-AddProject.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
.NAME
    AzDevOpsProject

.SYNOPSIS


.DESCRIPTION
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.PARAMETER ProjectName
    Key - System.String

.EXAMPLE 1

This example shows how to ensure that the Azure DevOps project
called 'Test Project' exists (or is added if it does not exist).

Configuration Example
{
    Import-DscResource -ModuleName 'AzureDevOpsDsc'

    node localhost
    {
        AzDevOpsProject 'AddProject'
        {
            Ensure               = 'Present'
            ProjectName          = 'Test Project'
        }
    }
}

'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        ModulePath = $mockSourcePath
                        DestinationModulePath = $mockDestinationModulePath
                        Verbose = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the resource is fully described and with several properties of different types' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName

    [DscProperty()]
    [System.String]$ProjectId

    [DscProperty()]
    [ValidateSet('Up', 'Down')]
    [System.String]$ValidateSetProperty

    [DscProperty(Mandatory)]
    [System.String]$MandatoryProperty

    [DscProperty(NotConfigurable)]
    [String[]]$Reasons
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockDestinationModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockSourceScript = @'
<#
    .SYNOPSIS
        A DSC Resource for Azure DevOps that
        represents the Project resource.

        This is another row.

    .DESCRIPTION
        A DSC Resource for Azure DevOps that
        represents the Project resource.

        This is another row.

    .PARAMETER ProjectName
        ProjectName description.

    .PARAMETER ProjectId
        ProjectId description.

        Second row with text.

    .PARAMETER MandatoryProperty
        MandatoryProperty description.

    .PARAMETER Reasons
        Reasons description.
#>
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName

    [DscProperty()]
    [System.String]$ProjectId

    [DscProperty()]
    [ValidateSet('Up', 'Down')]
    [System.String]$ValidateSetProperty

    [DscProperty(Mandatory)]
    [System.String]$MandatoryProperty

    [DscProperty(NotConfigurable)]
    [String[]]$Reasons
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
.NAME
    AzDevOpsProject

.SYNOPSIS
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.DESCRIPTION
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.PARAMETER ProjectName
    Key - System.String
    ProjectName description.

.PARAMETER ProjectId
    Write - System.String
    ProjectId description.

    Second row with text.

.PARAMETER ValidateSetProperty
    Write - System.String
    Allowed values: Up, Down

.PARAMETER MandatoryProperty
    Required - System.String
    MandatoryProperty description.

.PARAMETER Reasons
    Read - String[]
    Reasons description.

'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        ModulePath = $mockSourcePath
                        DestinationModulePath = $mockDestinationModulePath
                        Verbose = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When markdown code should be remove from text' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockDestinationModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockSourceScript = @'
<#
    .SYNOPSIS
        A DSC Resource for _Azure DevOps_ that
        represents the Project resource.

        This is another row.

    .DESCRIPTION
        A DSC Resource for _Azure DevOps_ that
        represents the Project resource.

        This is another row.

    .PARAMETER ProjectName
        ProjectName description. Use default value `MyProject`.
#>
[DscResource()]
class AzDevOpsProject
{
    [AzDevOpsProject] Get()
    {
        return [AzDevOpsProject] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String]$ProjectName
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
.NAME
    AzDevOpsProject

.SYNOPSIS
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.DESCRIPTION
    A DSC Resource for Azure DevOps that
    represents the Project resource.

    This is another row.

.PARAMETER ProjectName
    Key - System.String
    ProjectName description. Use default value MyProject.

'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        ModulePath = $mockSourcePath
                        DestinationModulePath = $mockDestinationModulePath
                        Verbose = $true
                        MarkdownCodeRegularExpression = @(
                            '\`(.+?)\`' # Match inline code-block
                            '_(.+?)_' # Match Italic (underscore)
                        )
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscResourcePowerShellHelp @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }
        }
    }
}
