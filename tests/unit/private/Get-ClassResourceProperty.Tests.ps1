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
        BeforeAll {

        }

        Context 'When the resource has a parent class that also has a DSC property' {
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
            }

            It 'Should return the expected DSC class resource properties' {
                $mockGetClassResourcePropertyParameters = @{
                    SourcePath = $mockSourcePath
                    BuiltModuleScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'
                    ClassName = @(
                        'ResourceBase'
                        'MyDscResource'
                    )
                }

                $getClassResourcePropertyResult = Get-ClassResourceProperty @mockGetClassResourcePropertyParameters
                $getClassResourcePropertyResult | Should -HaveCount 3
                $getClassResourcePropertyResult.Name | Should -Contain 'Ensure'
                $getClassResourcePropertyResult.Name | Should -Contain 'ProjectName'
                $getClassResourcePropertyResult.Name | Should -Contain 'ValidateSetProperty'

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({$_.Name -eq 'Ensure'})
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -Be 'Ensure description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({$_.Name -eq 'ProjectName'})
                $ensurePropertyResult.State | Should -Be 'Key'
                $ensurePropertyResult.Description | Should -Be 'ProjectName description.'
                $ensurePropertyResult.DataType | Should -Be 'System.String'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -BeNullOrEmpty

                $ensurePropertyResult = $getClassResourcePropertyResult.Where({$_.Name -eq 'ValidateSetProperty'})
                $ensurePropertyResult.State | Should -Be 'Write'
                $ensurePropertyResult.Description | Should -BeNullOrEmpty
                $ensurePropertyResult.DataType | Should -Be 'System.String[]'
                $ensurePropertyResult.IsArray | Should -BeFalse
                $ensurePropertyResult.ValueMap | Should -Contain 'Up'
                $ensurePropertyResult.ValueMap | Should -Contain 'Down'
            }
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
}
'@
            # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
            $mockBuiltModuleScript | Microsoft.PowerShell.Utility\Out-File -FilePath "$mockBuiltModulePath\MyClassModule.psm1" -Encoding ascii -Force

            # The source file of class DSC resource. This file is not actually referencing the base class to simplify the tests.
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
        }

        It 'Should return the expected DSC class resource properties' {
            $mockGetClassResourcePropertyParameters = @{
                SourcePath = $mockSourcePath
                BuiltModuleScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyClassModule.psm1'
                ClassName = @(
                    'ResourceBase'
                    'MyDscResource'
                )
            }

            $getClassResourcePropertyResult = Get-ClassResourceProperty @mockGetClassResourcePropertyParameters
            $getClassResourcePropertyResult | Should -HaveCount 2
            $getClassResourcePropertyResult.Name | Should -Contain 'Ensure'
            $getClassResourcePropertyResult.Name | Should -Contain 'ProjectName'

            $ensurePropertyResult = $getClassResourcePropertyResult.Where({$_.Name -eq 'Ensure'})
            $ensurePropertyResult.State | Should -Be 'Write'
            $ensurePropertyResult.Description | Should -BeNullOrEmpty
            $ensurePropertyResult.DataType | Should -Be 'System.String'
            $ensurePropertyResult.IsArray | Should -BeFalse

            $ensurePropertyResult = $getClassResourcePropertyResult.Where({$_.Name -eq 'ProjectName'})
            $ensurePropertyResult.State | Should -Be 'Key'
            $ensurePropertyResult.Description | Should -Be 'ProjectName description.'
            $ensurePropertyResult.DataType | Should -Be 'System.String'
            $ensurePropertyResult.IsArray | Should -BeFalse
        }
    }
}
