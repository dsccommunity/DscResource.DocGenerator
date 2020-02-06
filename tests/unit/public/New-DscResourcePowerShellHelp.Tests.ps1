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

    Describe 'New-DscResourcePowerShellHelp' {
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
}'

        # General mock values
        $script:mockReadmePath = Join-Path -Path $script:mockSchemaFolder -ChildPath 'readme.md'
        $script:mockOutputFile = Join-Path -Path $script:mockOutputPath -ChildPath "$($script:mockResourceName).md"
        $script:mockSavePath = Join-Path -Path $script:mockModulePath -ChildPath "DscResources\$($script:mockResourceName)\en-US\about_$($script:mockResourceName).help.txt"
        $script:mockOutputSavePath = Join-Path -Path $script:mockOutputPath -ChildPath "about_$($script:mockResourceName).help.txt"
        $script:mockDestinationModulePathSavePath = Join-Path -Path $script:mockDestinationModulePath -ChildPath "DscResources\$($script:mockResourceName)\en-US\about_$($script:mockResourceName).help.txt"
        $script:mockGetContentReadme = '# Description

The description of the resource.
Second row of description.
'
        $script:mockPowerShellHelpOutput = '.NAME
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
    Enum Description.

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

        $script:getTestPathReadme_parameterFilter = {
            $Path -eq $script:mockReadmePath
        }

        $script:getContentReadme_parameterFilter = {
            $Path -eq $script:mockReadmePath
        }

        $script:getDscResourceHelpExampleContent_parameterFilter = {
            $ExamplePath -eq $script:mockExampleFilePath -and $ExampleNumber -eq 1
        }

        $script:outFile_parameterFilter = {
            $FilePath -eq $script:mockSavePath
        }

        $script:outFileInputObject_parameterFilter = {
            $InputObject -eq $script:mockPowerShellHelpOutput -and
            $FilePath -eq $script:mockSavePath
        }

        $script:outFileOutputInputObject_parameterFilter = {
            $InputObject -eq $script:mockPowerShellHelpOutput -and
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
                    -CommandName Get-ChildItem `
                    -ParameterFilter $script:getChildItemSchema_parameterFilter

                Mock `
                    -CommandName Out-File `
                    -ParameterFilter $script:outFile_parameterFilter
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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
                    -MockWith { $false }

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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
                    -MockWith { $true }

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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
                    -MockWith { $true }

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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
                    -MockWith { $true }

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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
                    -MockWith { $true }

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
                    -CommandName Test-Path `
                    -ParameterFilter $script:getTestPathReadme_parameterFilter `
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
}
