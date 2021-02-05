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

    Describe 'New-DscResourceWikiPage' {
        Context 'When generating documentation for MOF-based resources' {
            $script:mockOutputPath = Join-Path -Path $TestDrive -ChildPath 'docs'
            $script:mockDestinationModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyModule\1.0.0'
            $script:mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'module'

            # Schema file info
            $script:mockResourceName = 'MyResource'
            $script:expectedSchemaPath = Join-Path -Path $script:mockSourcePath -ChildPath '\**\*.schema.mof'
            $script:mockSchemaBaseName = "MSFT_$($script:mockResourceName).schema"
            $script:mockSchemaFileName = "$($script:mockSchemaBaseName).mof"
            $script:mockSchemaFolder = Join-Path -Path $script:mockSourcePath -ChildPath "DSCResources\$($script:mockResourceName)"
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
                        Description      = 'Enum Description.'
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
            $script:mockExampleFilePath = Join-Path -Path $script:mockSourcePath -ChildPath "\Examples\Resources\$($script:mockResourceName)\$($script:mockResourceName)_Example1_Config.ps1"
            $script:expectedExamplePath = Join-Path -Path $script:mockSourcePath -ChildPath "\Examples\Resources\$($script:mockResourceName)\*.ps1"
            $script:mockExampleFiles = @(
                @{
                    Name     = "$($script:mockResourceName)_Example1_Config.ps1"
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
        MyResource Something
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
            $script:mockOutputFile = Join-Path -Path $script:mockOutputPath -ChildPath "$($script:mockResourceName).md"
            $script:mockSavePath = Join-Path -Path $script:mockOutputPath -ChildPath "$($script:mockResourceName).md"
            $script:mockDestinationModulePathSavePath = Join-Path -Path $script:mockDestinationModulePath -ChildPath "DscResources\$($script:mockResourceName)\en-US\about_$($script:mockResourceName).help.txt"
            $script:mockGetContentReadme = '# Description

The description of the resource.
Second row of description.
'
        $script:mockWikiContentOutput = "# MyResource

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **Id** | Key | String | Id Description | |
| **Enum** | Write | String | Enum Description. | Value1, Value2, Value3 |
| **Int** | Required | Uint32 | Int Description. | |
| **Read** | Read | String | Read Description. | |

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
        MyResource Something
        {
            Id    = 'MyId'
            Enum  = 'Value1'
            Int   = 1
        }
    }
}
" -replace '\r?\n', "`r`n"

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

            $script:getMofSchemaObjectSchema_parameterFilter = {
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

            $script:outFileInputObject_parameterFilter = {
                $InputObject -eq $script:mockWikiContentOutput -and
                $FilePath -eq $script:mockSavePath
            }

            $script:outFileOutputInputObject_parameterFilter = {
                $InputObject -eq $script:mockWikiContentOutput -and
                $FilePath -eq $script:mockSavePath
            }

            $script:writeWarningDescription_parameterFilter = {
                $Message -eq ($script:localizedData.NoDescriptionFileFoundWarning -f $script:mockResourceName)
            }

            $script:writeWarningMultipleDescription_parameterFilter = {
                $Message -eq ($script:localizedData.MultipleDescriptionFileFoundWarning -f $script:mockResourceName, 2)
            }

            $script:writeWarningExample_parameterFilter = {
                $Message -eq ($script:localizedData.NoExampleFileFoundWarning -f $script:mockResourceName)
            }

            # Function call parameters
            $script:newDscResourceWikiPage_parameters = @{
                SourcePath = $script:mockSourcePath
                Verbose    = $true
            }

            $script:newDscResourceWikiPageOutput_parameters = @{
                SourcePath      = $script:mockSourcePath
                OutputPath      = $script:mockOutputPath
                BuiltModulePath = '.' # Not used for MOF-based resources
                Verbose         = $true
            }

            $script:newDscResourceWikiPageDestinationModulePath_parameters = @{
                SourcePath            = $script:mockSourcePath
                DestinationModulePath = $script:mockDestinationModulePath
                Verbose               = $true
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
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
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
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

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
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
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
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith { return @(
                            @{ Name = 'README.MD'; FullName = $script:mockReadmePath },
                            @{ Name = 'Readme.md'; FullName = $script:mockReadmePath }) }

                    Mock `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFile_parameterFilter

                    Mock `
                        -CommandName Write-Warning `
                        -ParameterFilter $script:writeWarningMultipleDescription_parameterFilter
                }

                It 'Should not throw an exception' {
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
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
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith { return @(@{ Name = 'README.MD'; FullName = $script:mockReadmePath }) }

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
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
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
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith { return @(@{ Name = 'README.MD'; FullName = $script:mockReadmePath }) }


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
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileOutputInputObject_parameterFilter `
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
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith { $script:mockGetMofSchemaObject }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith { return @(@{ Name = 'README.MD'; FullName = $script:mockReadmePath }) }

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
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileInputObject_parameterFilter `
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
                        for the mocked function Get-MofSchemaObject.
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

                    $mockWikiContentOutput = "# MyResource

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **Id** | Key | String | Id Description | |
| **Enum** | Write | String | Enum Description. | Value1, Value2, Value3 |
| **Int** | Required | Uint32 | Int Description. | |
| **Read** | Read | String | Read Description. | |

### DSC_EmbeddedInstance

#### Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **EmbeddedId** | Key | String | Id Description | |
| **EmbeddedEnum** | Write | String | Enum Description. | Value1, Value2, Value3 |
| **EmbeddedInt** | Required | Uint32 | Int Description. | |
| **EmbeddedRead** | Read | String | Read Description. | |

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
        MyResource Something
        {
            Id    = 'MyId'
            Enum  = 'Value1'
            Int   = 1
        }
    }
}
" -replace '\r?\n', "`r`n"

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemSchema_parameterFilter `
                        -MockWith { $script:mockSchemaFiles }

                    Mock `
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
                        -MockWith {
                        return @(
                            $script:mockGetMofSchemaObject
                            $script:mockEmbeddedSchemaObject
                        )
                    }

                    Mock `
                        -CommandName Get-ChildItem `
                        -ParameterFilter $script:getChildItemDescription_parameterFilter `
                        -MockWith { return @(@{ Name = 'README.MD'; FullName = $script:mockReadmePath }) }

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
                    { New-DscResourceWikiPage @script:newDscResourceWikiPageOutput_parameters } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter {
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
                        -CommandName Get-MofSchemaObject `
                        -ParameterFilter $script:getMofSchemaObjectSchema_parameterFilter `
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
