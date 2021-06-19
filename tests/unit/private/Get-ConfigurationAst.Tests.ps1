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
    Describe 'Get-ConfigurationAst' {
        Context 'When the script file cannot be parsed' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyResourceModule\1.0.0'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

                $mockBuiltCompositeResourceScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyCompositeResource.schema.psm1'

                # The Configuration DSC resource in the built module.
                $mockBuiltCompositeResourceScript = @'
configuration CompositeHelperTest
{
    Node localhost
    {
        Dummy DoesNotExist
        {
            Ensure = 'Present'
        }
    }
}
'@

                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltCompositeResourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltCompositeResourceScriptFilePath -Encoding ascii -Force
            }

            if ($IsMacOs)
            {
                It 'Should throw a not implemented error' {
                    {
                        Get-ConfigurationAst -ScriptFile $mockBuiltCompositeResourceScriptFilePath
                    } | Should -Throw 'NotImplemented'
                }
            }
            else
            {
                It 'Should throw an error' {
                    # This evaluates just part of the expected error message.
                    { Get-ConfigurationAst -ScriptFile $mockBuiltCompositeResourceScriptFilePath } | Should -Throw "Undefined DSC resource 'Dummy'. Use Import-DSCResource to import the resource."
                }
            }
        }

        Context 'When the script file is parsed successfully' {
            BeforeAll {
                $mockBuiltModulePath = Join-Path -Path $TestDrive -ChildPath 'output\MyResourceModule\1.0.0'

                New-Item -Path $mockBuiltModulePath -ItemType 'Directory' -Force

                $mockBuiltCompositeResourceScriptFilePath = Join-Path -Path $mockBuiltModulePath -ChildPath 'MyCompositeResource.schema.psm1'

                # The Configuration DSC resource in the built module.
                $mockBuiltCompositeResourceScript = @'
configuration CompositeHelperTest1
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    # Composite resource code would be here.
}

configuration CompositeHelperTest2
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Name,

        [Parameter()]
        [ValidateSet('Present', 'Absent')]
        [System.String]
        $Ensure,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential
    )

    # Composite resource code would be here.
}
'@

                # Uses Microsoft.PowerShell.Utility\Out-File to override the stub that is needed for the mocks.
                $mockBuiltCompositeResourceScript | Microsoft.PowerShell.Utility\Out-File -FilePath $mockBuiltCompositeResourceScriptFilePath -Encoding ascii -Force
            }

            Context 'When returning all Configurationes in the script file' {
                if ($IsMacOS)
                {
                    It 'Should throw a not implemented error on MacOS' {
                        {
                            Get-ConfigurationAst -ScriptFile $mockBuiltCompositeResourceScriptFilePath
                        } | Should -Throw 'NotImplemented'
                    }
                }
                else
                {
                    It 'Should return the correct Configurationes' {
                        $astResult = Get-ConfigurationAst -ScriptFile $mockBuiltCompositeResourceScriptFilePath

                        $astResult | Should -HaveCount 2
                        $astResult.InstanceName.Value | Should -Contain 'CompositeHelperTest1'
                        $astResult.InstanceName.Value | Should -Contain 'CompositeHelperTest2'
                    }
                }
            }

            Context 'When returning a single Configuration from the script file' {
                if ($IsMacOS)
                {
                    It 'Should throw a not implemented error on MacOS' {
                        {
                            Get-ConfigurationAst -ScriptFile $mockBuiltCompositeResourceScriptFilePath -ConfigurationName 'CompositeHelperTest2'
                        } | Should -Throw 'NotImplemented'
                    }
                }
                else
                {
                    It 'Should return the correct Configurationes' {
                        $astResult = Get-ConfigurationAst -ScriptFile $mockBuiltCompositeResourceScriptFilePath -ConfigurationName 'CompositeHelperTest2'

                        $astResult | Should -HaveCount 1
                        $astResult.InstanceName.Value | Should -Be 'CompositeHelperTest2'
                    }
                }
            }
        }
    }
}
