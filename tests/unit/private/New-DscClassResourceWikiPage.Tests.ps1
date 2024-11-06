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

    Describe 'New-DscClassResourceWikiPage' {
        Context 'When generating documentation for class-based resources' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'
                $mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'source'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force
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

            Context 'When the resource is describe with just one key property with no description for resource or property' {
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

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
# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | | |

## Description
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

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
# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | | |

## Description

A DSC Resource for Azure DevOps that
represents the Project resource.

This is another row.
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

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
# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | | |

## Description

A DSC Resource for Azure DevOps that
represents the Project resource.

This is another row.

## Examples

### EXAMPLE 1

This example shows how to ensure that the Azure DevOps project
called 'Test Project' exists (or is added if it does not exist).

```powershell
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
```
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

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
# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | ProjectName description. | |
| **MandatoryProperty** | Required | System.String | MandatoryProperty description. | |
| **ProjectId** | Write | System.String | ProjectId description. Second row with text. | |
| **ValidateSetProperty** | Write | System.String | | `Up`, `Down` |
| **Reasons** | Read | String[] | Reasons description. | |

## Description

A DSC Resource for Azure DevOps that
represents the Project resource.

This is another row.
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the resource has a parent class that also has a DSC property' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
class ResourceBase
{
    hidden [System.String] $NotADscProperty

    [DscProperty()]
    [System.String]
    $Ensure
}

[DscResource()]
class AzDevOpsProject : ResourceBase
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockResourceSourceScript = @'
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
                    $mockResourceSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockBaseClassSourceScript = @'
<#
    .SYNOPSIS
        Synopsis for base class.

    .DESCRIPTION
        Description for base class

    .PARAMETER Ensure
        Ensure description.
#>
class ResourceBase
{
    hidden [System.String] $NotADscProperty

    [DscProperty()]
    [System.String]
    $Ensure
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBaseClassSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\001.ResourceBase.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | ProjectName description. | |
| **MandatoryProperty** | Required | System.String | MandatoryProperty description. | |
| **Ensure** | Write | System.String | Ensure description. | |
| **ProjectId** | Write | System.String | ProjectId description. Second row with text. | |
| **ValidateSetProperty** | Write | System.String | | `Up`, `Down` |
| **Reasons** | Read | String[] | Reasons description. | |

## Description

A DSC Resource for Azure DevOps that
represents the Project resource.

This is another row.
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When the resource has a parent class that also have a DSC property, but the property does not have a parameter description' {
                BeforeAll {
                    # The class DSC resource in the built module.
                    $mockBuiltModuleScript = @'
class ResourceBase
{
    [DscProperty()]
    [System.String]
    $Ensure
}

[DscResource()]
class AzDevOpsProject : ResourceBase
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

                    # The source file of class DSC resource.
                    $mockResourceSourceScript = @'
<#
    .SYNOPSIS
        Resource synopsis.

    .DESCRIPTION
        Resource description.

    .PARAMETER ProjectName
        ProjectName description.
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
                    $mockResourceSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.AzDevOpsProject.ps1" -Encoding ascii -Force

                    $mockBaseClassSourceScript = @'
class ResourceBase
{
    hidden [System.String] $NotADscProperty

    [DscProperty()]
    [System.String]
    $Ensure
}
'@
                    # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                    $mockBaseClassSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\001.ResourceBase.ps1" -Encoding ascii -Force

                    $mockExpectedFileOutput = @'
# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | ProjectName description. | |
| **Ensure** | Write | System.String | | |

## Description

Resource description.
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
                    } | Should -Not -Throw
                }

                It 'Should produce the correct output' {
                    Assert-MockCalled `
                        -CommandName Out-File `
                        -ParameterFilter $script:outFileContent_ParameterFilter `
                        -Exactly -Times 1 -Scope Context
                }
            }

            Context 'When adding metadata to the markdown file' {
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
                    $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

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
---
Module: MyClassModule
Type: ClassResource
---

# AzDevOpsProject

## Parameters

| Parameter | Attribute | DataType | Description | Allowed Values |
| --- | --- | --- | --- | --- |
| **ProjectName** | Key | System.String | | |

## Description
'@ -replace '\r?\n', "`r`n"

                    $mockNewDscResourcePowerShellHelpParameters = @{
                        SourcePath      = $mockSourcePath
                        BuiltModulePath = $mockBuiltModulePath
                        OutputPath      = $TestDrive
                        Verbose         = $true
                        Metadata        = @{
                            Type = 'ClassResource'
                            Module = 'MyClassModule'
                        }
                    }

                    Mock -CommandName Out-File
                }

                It 'Should not throw an exception' {
                    {
                        New-DscClassResourceWikiPage @mockNewDscResourcePowerShellHelpParameters
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
