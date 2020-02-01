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
    Describe 'Get-DscResourceHelpExampleContent' {
        # Parameter filters
        $script:getContentExample_parameterFilter = {
            $Path -eq $TestDrive
        }

        Context 'When a path to an example file with .EXAMPLE is passed and example number 1' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 1
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 1

Example Description.

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
'

            $script:mockGetContent = '<#
.EXAMPLE
Example Description.
#>
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
}' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }

        Context 'When a path to an example file with .DESCRIPTION is passed and example number 2' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 2
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 2

Example Description.

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
'

            $script:mockGetContent = '<#
    .DESCRIPTION
    Example Description.
#>
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
}' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }

        Context 'When a path to an example file with .SYNOPSIS is passed and example number 3' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 3
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 3

Example Description.

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
'

            $script:mockGetContent = '<#
    .SYNOPSIS
    Example Description.
#>
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
}' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }

        Context 'When a path to an example file with .SYNOPSIS and #Requires is passed and example number 4' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 4
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 4

Example Description.

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
'

            $script:mockGetContent = '#Requires -module MyModule
#Requires -module OtherModule
<#
    .SYNOPSIS
    Example Description.
#>
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
}' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }

        Context 'When a path to an example file with .DESCRIPTION, #Requires and PSScriptInfo is passed and example number 5' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 5
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 5

Example Description.

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
'

            $script:mockGetContent = '<#PSScriptInfo
.VERSION 1.0.0
.GUID 14b1346a-436a-4f64-af5c-b85119b819b3
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/CertificateDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/CertificateDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>
#Requires -module MyModule
#Requires -module OtherModule
<#
    .DESCRIPTION
        Example Description.
#>
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
}' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }

        Context 'When a path to an example file with .SYNOPSIS, .DESCRIPTION and PSScriptInfo is passed and example number 6' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 6
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 6

Example Synopsis.
Example Description.

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
'

            $script:mockGetContent = '<#PSScriptInfo
.VERSION 1.0.0
.GUID 14b1346a-436a-4f64-af5c-b85119b819b3
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/CertificateDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/CertificateDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>
<#
    .SYNOPSIS
        Example Synopsis.
    .DESCRIPTION
        Example Description.
#>
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
}' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }

        Context 'When a path to an example file from SharePointDsc resource module and example number 7' {
            $script:getDscResourceHelpExampleContent_parameters = @{
                ExamplePath   = $TestDrive
                ExampleNumber = 7
                Verbose       = $true
            }

            $script:mockExpectedResultContent = '.EXAMPLE 7

This example shows how to deploy Access Services 2013 to the local SharePoint farm.

    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc
        node localhost {
            SPAccessServiceApp AccessServices
            {
                Name                 = "Access Services Service Application"
                ApplicationPool      = "SharePoint Service Applications"
                DatabaseServer       = "SQL.contoso.local\SQLINSTANCE"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }
'

            $script:mockGetContent = '<#
.EXAMPLE
    This example shows how to deploy Access Services 2013 to the local SharePoint farm.
#>
    Configuration Example
    {
        param(
            [Parameter(Mandatory = $true)]
            [PSCredential]
            $SetupAccount
        )
        Import-DscResource -ModuleName SharePointDsc
        node localhost {
            SPAccessServiceApp AccessServices
            {
                Name                 = "Access Services Service Application"
                ApplicationPool      = "SharePoint Service Applications"
                DatabaseServer       = "SQL.contoso.local\SQLINSTANCE"
                PsDscRunAsCredential = $SetupAccount
            }
        }
    }' -split '\r?\n'

            BeforeAll {
                Mock `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -MockWith { $script:mockGetContent }
            }

            It 'Should not throw an exception' {
                { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
            }

            It 'Should return the expected string' {
                $script:result | Should -BeExactly $script:mockExpectedResultContent
            }

            It 'Should call the expected mocks ' {
                Assert-MockCalled `
                    -CommandName Get-Content `
                    -ParameterFilter $script:getContentExample_parameterFilter `
                    -Exactly -Times 1
            }
        }
    }

    Context 'When a path to an example file from CertificateDsc resource module and example number 8' {
        $script:getDscResourceHelpExampleContent_parameters = @{
            ExamplePath   = $TestDrive
            ExampleNumber = 8
            Verbose       = $true
        }

        $script:mockExpectedResultContent = '.EXAMPLE 8

Exports a certificate as a CERT using the friendly name to identify it.

Configuration CertificateExport_CertByFriendlyName_Config
{
    Import-DscResource -ModuleName CertificateDsc
    Node localhost
    {
        CertificateExport SSLCert
        {
            Type         = ''CERT''
            FriendlyName = ''Web Site SSL Certificate for www.contoso.com''
            Path         = ''c:\sslcert.cer''
        }
    }
}
'

        $script:mockGetContent = '<#PSScriptInfo
.VERSION 1.0.0
.GUID 14b1346a-436a-4f64-af5c-b85119b819b3
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.COPYRIGHT
.TAGS DSCConfiguration
.LICENSEURI https://github.com/PowerShell/CertificateDsc/blob/master/LICENSE
.PROJECTURI https://github.com/PowerShell/CertificateDsc
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES First version.
.PRIVATEDATA 2016-Datacenter,2016-Datacenter-Server-Core
#>
#Requires -module CertificateDsc
<#
    .DESCRIPTION
        Exports a certificate as a CERT using the friendly name to identify it.
#>
Configuration CertificateExport_CertByFriendlyName_Config
{
    Import-DscResource -ModuleName CertificateDsc
    Node localhost
    {
        CertificateExport SSLCert
        {
            Type         = ''CERT''
            FriendlyName = ''Web Site SSL Certificate for www.contoso.com''
            Path         = ''c:\sslcert.cer''
        }
    }
}' -split '\r?\n'

        BeforeAll {
            Mock `
                -CommandName Get-Content `
                -ParameterFilter $script:getContentExample_parameterFilter `
                -MockWith { $script:mockGetContent }
        }

        It 'Should not throw an exception' {
            { $script:result = Get-DscResourceHelpExampleContent @script:getDscResourceHelpExampleContent_parameters } | Should -Not -Throw
        }

        It 'Should return the expected string' {
            $script:result | Should -BeExactly $script:mockExpectedResultContent
        }

        It 'Should call the expected mocks ' {
            Assert-MockCalled `
                -CommandName Get-Content `
                -ParameterFilter $script:getContentExample_parameterFilter `
                -Exactly -Times 1
        }
    }
}
