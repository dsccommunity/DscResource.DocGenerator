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
    Describe 'Get-ClassResourceProperty' {
        Context 'When the resource has a parent class that also has a DSC property' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'
                $mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'source'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force
                New-Item -Path "$mockSourcePath\Classes" -ItemType 'Directory' -Force

                # The class DSC resource in the built module.
                $mockBuiltModuleScript = @'
enum ResourceEnum
{
    Value1
    Value2
    Value3
}

class ResourceBase
{
    hidden [System.String] $NotADscProperty

    [DscProperty()]
    [System.String]
    $Ensure
}

[DscResource()]
class MyDscResource : ResourceBase
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName

    [DscProperty()]
    [ValidateSet('Up', 'Down')]
    [System.String[]] $ValidateSetProperty

    [DscProperty()]
    [ResourceEnum] $EnumProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

                <#
                    The source file of class DSC resource. This file is not actually
                    referencing the base class to simplify the tests.
                    The property ValidateSetProperty does not have a parameter description
                    to be able to test missing description.
                #>
                $mockResourceSourceScript = @'
enum ResourceEnum
{
    Value1
    Value2
    Value3
}

<#
    .SYNOPSIS
    Resource synopsis.

    .DESCRIPTION
    Resource description.

    .PARAMETER ProjectName
    ProjectName description.
#>
[DscResource()]
class MyDscResource
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName

    [DscProperty()]
    [ValidateSet('Up', 'Down')]
    [System.String[]] $ValidateSetProperty

    [DscProperty()]
    [ResourceEnum] $EnumProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockResourceSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.MyDscResource.ps1" -Encoding ascii -Force

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

                [System.IO.FileInfo] $mockBuiltModuleFile = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'
                Import-Module $mockBuiltModuleFile.FullName -Force

                $classesInModule = (Get-Module $mockBuiltModuleFile.BaseName).ImplementingAssembly.DefinedTypes | Where-Object { $_.IsClass -and $_.IsPublic }
                $dscClassInModule = $classesInModule | Where-Object { 'DscResourceAttribute' -in $_.CustomAttributes.AttributeType.Name }

                $dscProperties = $dscClassInModule.GetProperties() | Where-Object { 'DscPropertyAttribute' -in $_.CustomAttributes.AttributeType.Name }
            }

            It 'Should return the expected DSC class resource properties' {
                $mockGetClassResourcePropertyParameters = @{
                    SourcePath = $mockSourcePath
                    Properties = $dscProperties
                }

                $getClassResourcePropertyResult = Get-ClassResourceProperty @mockGetClassResourcePropertyParameters
                $getClassResourcePropertyResult | Should -HaveCount 4
                $getClassResourcePropertyResult.Name | Should -Contain 'Ensure'
                $getClassResourcePropertyResult.Name | Should -Contain 'ProjectName'
                $getClassResourcePropertyResult.Name | Should -Contain 'ValidateSetProperty'
                $getClassResourcePropertyResult.Name | Should -Contain 'EnumProperty'

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'Ensure' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -Be 'Ensure description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ProjectName' })
                $ensurePropertyResult.State | Should -Be 'Key'
                $ensurePropertyResult.Description | Should -Be 'ProjectName description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ValidateSetProperty' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeNullOrEmpty
                $ensurePropertyResult.DataType | Should -Be 'System.String[]'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -Contain 'Up'
                $ensurePropertyResult.ValueMap | Should -Contain 'Down'

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'EnumProperty' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeNullOrEmpty
                $ensurePropertyResult.DataType | Should -Be 'ResourceEnum'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -Contain 'Value1'
                $ensurePropertyResult.ValueMap | Should -Contain 'Value2'
                $ensurePropertyResult.ValueMap | Should -Contain 'Value3'
            }
        }

        Context 'When the resource has a parent class that does not have a source file (part of another module)' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'
                $mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'source'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force
                New-Item -Path "$mockSourcePath\Classes" -ItemType 'Directory' -Force

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
class MyDscResource : ResourceBase
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName

    [DscProperty()]
    [ValidateSet('Up', 'Down')]
    [System.String[]] $ValidateSetProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

                <#
                The source file of class DSC resource. This file is not actually
                referencing the base class to simplify the tests.
                The property ValidateSetProperty does not have a parameter description
                to be able to test missing description.
            #>
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
class MyDscResource
{
[MyDscResource] Get()
{
    return [MyDscResource] $this
}

[System.Boolean] Test()
{
    return $true
}

[void] Set() {}

[DscProperty(Key)]
[System.String] $ProjectName

[DscProperty()]
[ValidateSet('Up', 'Down')]
[System.String[]] $ValidateSetProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockResourceSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.MyDscResource.ps1" -Encoding ascii -Force

                [System.IO.FileInfo] $mockBuiltModuleFile = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'
                Import-Module $mockBuiltModuleFile.FullName -Force

                $classesInModule = (Get-Module $mockBuiltModuleFile.BaseName).ImplementingAssembly.DefinedTypes | Where-Object { $_.IsClass -and $_.IsPublic }
                $dscClassInModule = $classesInModule | Where-Object { 'DscResourceAttribute' -in $_.CustomAttributes.AttributeType.Name }

                $dscProperties = $dscClassInModule.GetProperties() | Where-Object { 'DscPropertyAttribute' -in $_.CustomAttributes.AttributeType.Name }
            }

            It 'Should return the expected DSC class resource properties' {
                $mockGetClassResourcePropertyParameters = @{
                    SourcePath = $mockSourcePath
                    Properties = $dscProperties
                }

                $getClassResourcePropertyResult = Get-ClassResourceProperty @mockGetClassResourcePropertyParameters
                $getClassResourcePropertyResult | Should -HaveCount 2
                $getClassResourcePropertyResult.Name | Should -Contain 'ProjectName'
                $getClassResourcePropertyResult.Name | Should -Contain 'ValidateSetProperty'

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ProjectName' })
                $ensurePropertyResult.State | Should -Be 'Key'
                $ensurePropertyResult.Description | Should -Be 'ProjectName description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ValidateSetProperty' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeNullOrEmpty
                $ensurePropertyResult.DataType | Should -Be 'System.String[]'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -Contain 'Up'
                $ensurePropertyResult.ValueMap | Should -Contain 'Down'
            }
        }

        Context 'When a base class is missing comment-based help' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'
                $mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'source'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force
                New-Item -Path "$mockSourcePath\Classes" -ItemType 'Directory' -Force

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
class MyDscResource : ResourceBase
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName

    [DscProperty()]
    [System.String] $DescriptionTestProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

                <#
                The source file of class DSC resource. This file is not actually
                referencing the base class to simplify the tests.

                The property DescriptionTestProperty is used to test description
                parsing.
            #>
                $mockResourceSourceScript = @'
<#
.SYNOPSIS
    Resource synopsis.

    .DESCRIPTION
    Resource description.

    .PARAMETER ProjectName
    ProjectName description.

    .PARAMETER DescriptionTestProperty
    DescriptionTestProperty description.

    This is  a second row with | various tests like double space and vertical bar.
#>
[DscResource()]
class MyDscResource
{
    [MyDscResource] Get()
    {
        return [MyDscResource] $this
    }

    [System.Boolean] Test()
    {
        return $true
    }

    [void] Set() {}

    [DscProperty(Key)]
    [System.String] $ProjectName

    [DscProperty()]
    [System.String] $DescriptionTestProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockResourceSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.MyDscResource.ps1" -Encoding ascii -Force

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

                [System.IO.FileInfo] $mockBuiltModuleFile = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'
                Import-Module $mockBuiltModuleFile.FullName -Force

                $classesInModule = (Get-Module $mockBuiltModuleFile.BaseName).ImplementingAssembly.DefinedTypes | Where-Object { $_.IsClass -and $_.IsPublic }
                $dscClassInModule = $classesInModule | Where-Object { 'DscResourceAttribute' -in $_.CustomAttributes.AttributeType.Name }

                $dscProperties = $dscClassInModule.GetProperties() | Where-Object { 'DscPropertyAttribute' -in $_.CustomAttributes.AttributeType.Name }
            }

            It 'Should return the expected DSC class resource properties' {
                $mockGetClassResourcePropertyParameters = @{
                    SourcePath = $mockSourcePath
                    Properties = $dscProperties
                }

                $getClassResourcePropertyResult = Get-ClassResourceProperty @mockGetClassResourcePropertyParameters
                $getClassResourcePropertyResult | Should -HaveCount 3
                $getClassResourcePropertyResult.Name | Should -Contain 'Ensure'
                $getClassResourcePropertyResult.Name | Should -Contain 'ProjectName'
                $getClassResourcePropertyResult.Name | Should -Contain 'DescriptionTestProperty'

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'Ensure' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeNullOrEmpty
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ProjectName' })
                $ensurePropertyResult.State | Should -Be 'Key'
                $ensurePropertyResult.Description | Should -Be 'ProjectName description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'DescriptionTestProperty' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeExactly @'
DescriptionTestProperty description. This is a second row with various tests like double space and vertical bar.
'@
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
            }
        }

        Context 'When two script file names end with similar name' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyClassModule\1.0.0'
                $mockSourcePath = Join-Path -Path $TestDrive -ChildPath 'source'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force
                New-Item -Path "$mockSourcePath\Classes" -ItemType 'Directory' -Force

                # The class DSC resource in the built module.
                $mockBuiltModuleScript = @'
class BaseMyDscResource
{
hidden [System.String] $NotADscProperty

[DscProperty()]
[System.String]
$Ensure
}

[DscResource()]
class MyDscResource : BaseMyDscResource
{
[MyDscResource] Get()
{
    return [MyDscResource] $this
}

[System.Boolean] Test()
{
    return $true
}

[void] Set() {}

[DscProperty(Key)]
[System.String] $ProjectName

[DscProperty()]
[ValidateSet('Up', 'Down')]
[System.String[]] $ValidateSetProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

                <#
                The source file of class DSC resource. This file is not actually
                referencing the base class to simplify the tests.
                The property ValidateSetProperty does not have a parameter description
                to be able to test missing description.
            #>
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
class MyDscResource
{
[MyDscResource] Get()
{
    return [MyDscResource] $this
}

[System.Boolean] Test()
{
    return $true
}

[void] Set() {}

[DscProperty(Key)]
[System.String] $ProjectName

[DscProperty()]
[ValidateSet('Up', 'Down')]
[System.String[]] $ValidateSetProperty
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockResourceSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\010.MyDscResource.ps1" -Encoding ascii -Force

                $mockBaseClassSourceScript = @'
<#
.SYNOPSIS
Synopsis for base class.

.DESCRIPTION
Description for base class

.PARAMETER Ensure
Ensure description.
#>
class BaseMyDscResource
{
hidden [System.String] $NotADscProperty

[DscProperty()]
[System.String]
$Ensure
}
'@
                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBaseClassSourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockSourcePath\Classes\001.BaseMyDscResource.ps1" -Encoding ascii -Force

                [System.IO.FileInfo] $mockBuiltModuleFile = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'
                Import-Module -Name $mockBuiltModuleFile.FullName -Force

                $classesInModule = (Get-Module $mockBuiltModuleFile.BaseName).ImplementingAssembly.DefinedTypes | Where-Object { $_.IsClass -and $_.IsPublic }
                $dscClassInModule = $classesInModule | Where-Object { 'DscResourceAttribute' -in $_.CustomAttributes.AttributeType.Name }

                $dscProperties = $dscClassInModule.GetProperties() | Where-Object { 'DscPropertyAttribute' -in $_.CustomAttributes.AttributeType.Name }
            }

            It 'Should return the expected DSC class resource properties' {
                $mockGetClassResourcePropertyParameters = @{
                    SourcePath = $mockSourcePath
                    Properties = $dscProperties
                }

                $getClassResourcePropertyResult = Get-ClassResourceProperty @mockGetClassResourcePropertyParameters
                #$getClassResourcePropertyResult | Should -HaveCount 3
                $getClassResourcePropertyResult.Name | Should -Contain 'Ensure'
                $getClassResourcePropertyResult.Name | Should -Contain 'ProjectName'
                $getClassResourcePropertyResult.Name | Should -Contain 'ValidateSetProperty'

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'Ensure' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -Be 'Ensure description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ProjectName' })
                $ensurePropertyResult.State | Should -Be 'Key'
                $ensurePropertyResult.Description | Should -Be 'ProjectName description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({ $_.Name -eq 'ValidateSetProperty' })
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeNullOrEmpty
                $ensurePropertyResult.DataType | Should -Be 'System.String[]'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -Contain 'Up'
                $ensurePropertyResult.ValueMap | Should -Contain 'Down'
            }
        }
    }
}
