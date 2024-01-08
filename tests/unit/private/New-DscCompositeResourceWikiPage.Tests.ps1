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
            [System.Management.Automation.SwitchParameter]
            $Force
        )

        throw 'StubNotImplemented'
    }

    Describe 'New-DscCompositeResourceWikiPage' {
        Context 'When generating documentation for composite resources' {
            $script:mockOutputPath = Join-Path -Path $TestDrive -ChildPath 'docs'
            $script:mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'module'

            # Schema file info
            $script:mockCompositeResourceName = 'MyCompositeResource'
            $script:expectedSchemaPath = Join-Path -Path $script:mockSourcePath -ChildPath '\**\*.schema.psm1'
            $script:mockSchemaBaseName = "$($script:mockCompositeResourceName).schema"
            $script:mockSchemaFileName = "$($script:mockSchemaBaseName).psm1"
            $script:mockSchemaFolder = Join-Path -Path $script:mockSourcePath -ChildPath "DSCResources\$($script:mockCompositeResourceName)"
            $script:mockSchemaFilePath = Join-Path -Path $script:mockSchemaFolder -ChildPath $script:mockSchemaFileName
            $script:mockSchemaFiles = @(
                @{
                    FullName      = $script:mockSchemaFilePath
                    Name          = $script:mockSchemaFileName
                    DirectoryName = $script:mockSchemaFolder
                    BaseName      = $script:mockSchemaBaseName
                }
            )

            $script:mockGetCompositeSchemaObject = @{
                Name       = 'MyCompositeResource'
                Parameters = @(
                    @{
                        Name             = 'StringProperty'
                        State            = 'Required'
                        Type             = 'String'
                        ValidateSet      = $null
                        Description      = 'Any description'
                    }
                    @{
                        Name             = 'StringValueMapProperty'
                        State            = 'Required'
                        Type             = 'String'
                        ValidateSet      = @(
                            'Value1'
                            'Value2'
                        )
                        Description      = 'Any description'
                    }
                    @{
                        Name             = 'StringArrayWriteProperty'
                        State            = 'Write'
                        Type             = 'String[]'
                        ValidateSet      = $null
                        Description      = 'Any description'
                    }
                )
                ModuleVersion = '1.0.0'
                Description   = 'Composite resource.'
            }

            # Example file info
            $script:mockExampleFilePath = Join-Path -Path $script:mockSourcePath -ChildPath "\Examples\Resources\$($script:mockCompositeResourceName)\$($script:mockCompositeResourceName)_Example1_Config.ps1"
            $script:expectedExamplePath = Join-Path -Path $script:mockSourcePath -ChildPath "\Examples\Resources\$($script:mockCompositeResourceName)\*.ps1"
            $script:mockExampleFiles = @(
                @{
                    Name     = "$($script:mockCompositeResourceName)_Example1_Config.ps1"
                    FullName = $script:mockExampleFilePath
                }
            )

            $script:mockExampleContent = '.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyCompositeResource Something
        {
            Id    = ''MyId''
            Enum  = ''Value1''
            Int   = 1
        }
    }
}'

            # General mock values
            $script:mockReadmePath = Join-Path -Path $script:mockSchemaFolder -ChildPath 'readme.md'
            $script:mockReadmeFolder = $script:mockSchemaFolder
            $script:mockOutputFile = Join-Path -Path $script:mockOutputPath -ChildPath "$($script:mockCompositeResourceName).md"
            $script:mockSavePath = Join-Path -Path $script:mockOutputPath -ChildPath "$($script:mockCompositeResourceName).md"
            $script:mockGetContentReadme = '# Description

The description of the resource.
Second row of description.
'
            $script:mockWikiContentOutput = '# MyCompositeResource

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **StringProperty** | Required | String | Any description | |
| **StringValueMapProperty** | Required | String | Any description | `Value1`, `Value2` |
| **StringArrayWriteProperty** | Write | String[] | Any description | |

## Description

The description of the resource.
Second row of description.

## Examples

.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyCompositeResource Something
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

            $script:getChildItemDescription_parameterFilter = {
                $Path -eq $script:mockReadmeFolder
            }

            $script:getChildItemExample_parameterFilter = {
                $Path -eq $script:expectedExamplePath
            }

            $script:getCompositeSchemaObjectSchema_parameterFilter = {
                $Filename -eq $script:mockSchemaFilePath
            }

            $script:getTestPathReadme_parameterFilter = {
                $Path -eq $script:mockReadmePath
            }

            $script:getContentReadme_parameterFilter = {
                $Path -eq $script:mockReadmePath
            }

            $script:getDscResourceWikiExampleContent_parameterFilter = {
                $ExamplePath -eq $script:mockExampleFilePath -and $ExampleNumber -eq 1
            }

            $script:outFile_parameterFilter = {
                $FilePath -eq $script:mockSavePath
            }

            $script:outFileContent_parameterFilter = {
                if ($InputObject -ne $script:mockWikiContentOutput)
                {
                    # Helper to output the diff.
                    Out-Diff -Expected $script:mockWikiContentOutput -Actual $InputObject
                }

                $InputObject -eq $script:mockWikiContentOutput
            }

            $script:writeWarningDescription_parameterFilter = {
                $Message -eq ($script:localizedData.NoDescriptionFileFoundWarning -f $script:mockCompositeResourceName)
            }

            $script:writeWarningMultipleDescription_parameterFilter = {
                $Message -eq ($script:localizedData.MultipleDescriptionFileFoundWarning -f $script:mockCompositeResourceName, 2)
            }

            $script:writeWarningExample_parameterFilter = {
                $Message -eq ($script:localizedData.NoExampleFileFoundWarning -f $script:mockCompositeResourceName)
            }

            # Function call parameters
            $script:newDscResourceWikiPage_parameters = @{
                SourcePath = $script:mockSourcePath
                Verbose    = $true
            }

            $script:newDscResourceWikiPageOutput_parameters = @{
                SourcePath      = $script:mockSourcePath
                OutputPath      = $script:mockOutputPath
                BuiltModulePath = '.' # Not used for composite resources
                Verbose         = $true
            }

            Context 'When there are no schemas found in the module folder' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
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
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetCompositeSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith { $null }

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
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

            Context 'When there are multiple resource descriptions found' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetCompositeSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith {
                            return @(
                                @{
                                    Name = 'README.MD'
                                    FullName = $script:mockReadmePath
                                },
                                @{
                                    Name = 'Readme.md'
                                    FullName = $script:mockReadmePath
                                }
                            )
                        }

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningMultipleDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningMultipleDescription_parameterFilter `
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
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetCompositeSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith {
                            return @(
                                @{
                                    Name = 'README.MD'
                                    FullName = $script:mockReadmePath
                                }
                            )
                        }

                    Mock `
                        -CommandName Get-Content `
                        -ParameterFilter $script:getContentReadme_parameterFilter `
                        -MockWith { $script:mockGetContentReadme }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemExample_parameterFilter

                    Mock `
                        -CommandName Get-DscResourceWikiExampleContent

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningExample_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetCompositeSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith {
                            return @(
                                @{
                                    Name = 'README.MD'
                                    FullName = $script:mockReadmePath
                                }
                            )
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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

            Context 'When there is one schema found in the module folder and one example using .EXAMPLE and only the parameter SourcePath is specified' {
                BeforeAll {
                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetCompositeSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith {
                            return @(
                                @{
                                    Name = 'README.MD'
                                    FullName = $script:mockReadmePath
                                }
                            )
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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

            Context 'When the schema is using an embedded instance' {
                BeforeAll {
                    <#
                        This is the mocked embedded schema that is to be returned
                        together with the resource schema (which is mocked above)
                        for the mocked function Get-CompositeSchemaObject.
                    #>
                    $script:mockEmbeddedSchemaObject = @{
                        ClassName    = 'DSC_EmbeddedInstance'
                        ClassVersion = '1.0.0'
                        FriendlyName = 'EmbeddedInstance'
                        Attributes   = @(
                            @{
                                State            = 'Key'
                                DataType         = 'String'
                                ValueMap         = @()
                                IsArray          = $false
                                Name             = 'EmbeddedId'
                                Description      = 'Id Description'
                                EmbeddedInstance = ''
                            },
                            @{
                                State            = 'Write'
                                DataType         = 'String'
                                ValueMap         = @( 'Value1', 'Value2', 'Value3' )
                                IsArray          = $false
                                Name             = 'EmbeddedEnum'
                                Description      = 'Enum Description.'
                                EmbeddedInstance = ''
                            },
                            @{
                                State            = 'Required'
                                DataType         = 'Uint32'
                                ValueMap         = @()
                                IsArray          = $false
                                Name             = 'EmbeddedInt'
                                Description      = 'Int Description.'
                                EmbeddedInstance = ''
                            },
                            @{
                                State            = 'Read'
                                DataType         = 'String'
                                ValueMap         = @()
                                IsArray          = $false
                                Name             = 'EmbeddedRead'
                                Description      = 'Read Description.'
                                EmbeddedInstance = ''
                            }
                        )
                    }

                    $mockWikiContentOutput = '# MyCompositeResource

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **StringProperty** | Required | String | Any description | |
| **StringValueMapProperty** | Required | String | Any description | `Value1`, `Value2` |
| **StringArrayWriteProperty** | Write | String[] | Any description | |

## Description

The description of the resource.
Second row of description.

## Examples

.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyCompositeResource Something
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
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith {
                        return @(
                            $script:mockGetCompositeSchemaObject
                            $script:mockEmbeddedSchemaObject
                        )
                    }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith {
                            return @(
                                @{
                                    Name = 'README.MD'
                                    FullName = $script:mockReadmePath
                                }
                            )
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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
                    { New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter {
                            if ($InputObject -ne $mockWikiContentOutput)
                            {
                                # Helper to output the diff.
                                Out-Diff -Expected $mockWikiContentOutput -Actual $InputObject
                            }

                            $InputObject -eq $mockWikiContentOutput
                        } `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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

            Context 'When adding metadata to the markdown file' {
                BeforeAll {
                    <#
                        This is the mocked embedded schema that is to be returned
                        together with the resource schema (which is mocked above)
                        for the mocked function Get-CompositeSchemaObject.
                    #>
                    $script:mockEmbeddedSchemaObject = @{
                        ClassName    = 'DSC_EmbeddedInstance'
                        ClassVersion = '1.0.0'
                        FriendlyName = 'EmbeddedInstance'
                        Attributes   = @(
                            @{
                                State            = 'Key'
                                DataType         = 'String'
                                ValueMap         = @()
                                IsArray          = $false
                                Name             = 'EmbeddedId'
                                Description      = 'Id Description'
                                EmbeddedInstance = ''
                            },
                            @{
                                State            = 'Write'
                                DataType         = 'String'
                                ValueMap         = @( 'Value1', 'Value2', 'Value3' )
                                IsArray          = $false
                                Name             = 'EmbeddedEnum'
                                Description      = 'Enum Description.'
                                EmbeddedInstance = ''
                            },
                            @{
                                State            = 'Required'
                                DataType         = 'Uint32'
                                ValueMap         = @()
                                IsArray          = $false
                                Name             = 'EmbeddedInt'
                                Description      = 'Int Description.'
                                EmbeddedInstance = ''
                            },
                            @{
                                State            = 'Read'
                                DataType         = 'String'
                                ValueMap         = @()
                                IsArray          = $false
                                Name             = 'EmbeddedRead'
                                Description      = 'Read Description.'
                                EmbeddedInstance = ''
                            }
                        )
                    }

                    $mockWikiContentOutput = '---
Type: CompositeResource
Module: MyClassModule
---

# MyCompositeResource

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **StringProperty** | Required | String | Any description | |
| **StringValueMapProperty** | Required | String | Any description | `Value1`, `Value2` |
| **StringArrayWriteProperty** | Write | String[] | Any description | |

## Description

The description of the resource.
Second row of description.

## Examples

.EXAMPLE 1

Example description.

Configuration Example
{
    Import-DSCResource -ModuleName MyModule
    Node localhost
    {
        MyCompositeResource Something
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
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -MockWith {
                        return @(
                            $script:mockGetCompositeSchemaObject
                            $script:mockEmbeddedSchemaObject
                        )
                    }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith {
                            return @(
                                @{
                                    Name = 'README.MD'
                                    FullName = $script:mockReadmePath
                                }
                            )
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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
                        New-DscCompositeResourceWikiPage @script:newDscResourceWikiPageOutput_parameters -Metadata @{
                            Type = 'CompositeResource'
                            Module = 'MyClassModule'
                        }
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter {
                            if ($InputObject -ne $mockWikiContentOutput)
                            {
                                # Helper to output the diff.
                                Out-Diff -Expected $mockWikiContentOutput -Actual $InputObject
                            }

                            $InputObject -eq $mockWikiContentOutput
                        } `
                        -Exactly -Times 1
                }

                It 'Should call the expected mocks ' {
                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-CompositeSchemaObject `
                        -ParameterFilter $script:getCompositeSchemaObjectSchema_parameterFilter `
                        -Exactly -Times 1

                    Assert-MockCalled `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
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
                        -CommandName Get-DscResourceWikiExampleContent `
                        -ParameterFilter $script:getDscResourceWikiExampleContent_parameterFilter `
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
    }
}
