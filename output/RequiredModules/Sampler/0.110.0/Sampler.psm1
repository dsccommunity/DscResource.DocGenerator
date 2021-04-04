#Region './Private/Get-SamplerProjectModuleManifest.ps1' 0

<#
    .SYNOPSIS
        Gets the path to the Module manifest in the source folder.

    .DESCRIPTION
        This command finds the Module Manifest of the current Sampler project,
        regardless of the name of the source folder (src, source, or MyProjectName).
        It looks for psd1 that are not build.psd1 or analyzersettings, 1 folder under
        the $BuildRoot, and where a property ModuleVersion is set.

        This allows to deduct the Module name's from that module Manifest.

    .PARAMETER BuildRoot
        Root folder where the build is called, usually the root of the repository.

    .EXAMPLE
        Get-SamplerProjectModuleManifest -BuildRoot .

#>
function Get-SamplerProjectModuleManifest
{
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    $excludeFiles = @(
        'build.psd1'
        'analyzersettings.psd1'
    )

    $moduleManifestItem = Get-ChildItem -Path "$BuildRoot\*\*.psd1" -Exclude $excludeFiles |
            Where-Object -FilterScript {
                ($_.Directory.Name -match 'source|src' -or $_.Directory.Name -eq $_.BaseName) -and
                $(Test-ModuleManifest -Path $_.FullName -ErrorAction 'SilentlyContinue' ).Version
            }

    if ($moduleManifestItem.Count -gt 1)
    {
        throw ("Found more than one project folder containing a module manifest, please make sure there are only one; `n Manifest: {0}" -f ($moduleManifestItem.FullName -join "`n Manifest: "))
    }
    else
    {
        return $moduleManifestItem
    }
}
#EndRegion './Private/Get-SamplerProjectModuleManifest.ps1' 52
#Region './Public/Add-Sample.ps1' 0

<#
    .SYNOPSIS
        Adding code elements (function, enum, class, DSC Resource, tests...) to a module's source.

    .DESCRIPTION
        Add-Sample is an helper function to invoke a plaster template built-in the Sampler module.
        With this function you can bootstrap your module project by adding classes, functions and
        associated tests, examples and configuration elements.

    .PARAMETER Sample
        Specifies a sample component based on the Plaster templates embedded with this module.
        The available types of module elements are:
            - Classes: A sample of 4 classes with inheritence and how to manage the orders to avoid parsing errors.
            - ClassResource: A Class-Based DSC Resources showing some best practices including tests, Reasons, localized strings.
            - Composite: A DSC Composite Resource (a configuration block) packaged the right way to make sure it's visible by Get-DscResource.
            - Enum: An example of a simple Enum.
            - MofResource: A sample of a MOF-Based DSC Resource following the DSC Community practices.
            - PrivateFunction: A sample of a Private function (not exported from the module) and its test.
            - PublicCallPrivateFunctions: A sample of 2 functions where the exported one (public) calls the private one, with the tests.
            - PublicFunction: A sample public function and its test.

    .PARAMETER DestinationPath
        Destination of your module source root folder, defaults to the current directory ".".
        We assume that your current location is the module folder, and within this folder we
        will find the source folder, the tests folder and other supporting files.

    .EXAMPLE
        C:\src\MyModule> Add-Sample -Sample PublicFunction -PublicFunctionName Get-MyStuff

    .NOTES
        This module requires and uses Plaster.
#>
function Add-Sample
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding()]
    [OutputType()]
    param
    (
        [Parameter()]
        # Add a sample component based on the Plaster templates embedded with this module.
        [ValidateSet('Classes', 'ClassFolderResource', 'ClassResource', 'Composite', 'Enum', 'Examples', 'GithubConfig', 'GCPackage', 'HelperSubModules', 'MofResource', 'PrivateFunction', 'PublicCallPrivateFunctions', 'PublicFunction', 'VscodeConfig')]
        [string]
        $Sample,

        [Parameter()]
        [System.String]
        $DestinationPath = '.'
    )

    dynamicparam
    {
        $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary

        if ($null -eq $Sample)
        {
            return
        }

        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder

        $previousErrorActionPreference = $ErrorActionPreference

        try
        {
            <#
                Let's convert non-terminating errors in this function to terminating so we
                catch and format the error message as a warning.
            #>
            $ErrorActionPreference = 'Stop'

            <#
                The constrained runspace is not available in the dynamicparam block.  Shouldn't be needed
                since we are only evaluating the parameters in the manifest - no need for EvaluateConditionAttribute as we
                are not building up multiple parameter sets.  And no need for EvaluateAttributeValue since we are only
                grabbing the parameter's value which is static.
            #>
            $templateAbsolutePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TemplatePath)

            if (-not (Test-Path -LiteralPath $templateAbsolutePath -PathType 'Container'))
            {
                throw ("Can't find plaster template at {0}." -f $templateAbsolutePath)
            }

            $plasterModule = Get-Module -Name 'Plaster'

            <#
                Load manifest file using culture lookup (using Plaster module private function GetPlasterManifestPathForCulture).
                This is the current function that is called:
                https://github.com/PowerShellOrg/Plaster/blob/0506a26ffb532a335a4e62a8da31d9ca0177ae2a/src/InvokePlaster.ps1#L1478
            #>
            $manifestPath = & $plasterModule {
                param
                (
                    [Parameter()]
                    [System.String]
                    $templateAbsolutePath,

                    [Parameter()]
                    [System.String]
                    $Culture
                )

                GetPlasterManifestPathForCulture -TemplatePath $templateAbsolutePath -Culture $Culture
            } $templateAbsolutePath $PSCulture

            if (($null -eq $manifestPath) -or (-not (Test-Path -Path $manifestPath)))
            {
                return
            }

            $manifest = Plaster\Test-PlasterManifest -Path $manifestPath -ErrorAction Stop 3>$null

            <#
                The user-defined parameters in the Plaster manifest are converted to dynamic parameters
                which allows the user to provide the parameters via the command line.
                This enables non-interactive use cases.
            #>
            foreach ($node in $manifest.plasterManifest.Parameters.ChildNodes)
            {
                if ($node -isnot [System.Xml.XmlElement])
                {
                    continue
                }

                $name = $node.name
                $type = $node.type

                if ($node.prompt)
                {
                    $prompt = $node.prompt
                }
                else
                {
                    $prompt = "Missing Parameter $name"
                }

                if (-not $name -or -not $type)
                {
                    continue
                }

                # Configure ParameterAttribute and add to attr collection.
                $attributeCollection = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                $paramAttribute = New-Object -TypeName System.Management.Automation.ParameterAttribute
                $paramAttribute.HelpMessage = $prompt
                $attributeCollection.Add($paramAttribute)

                switch -regex ($type)
                {
                    'text|user-fullname|user-email'
                    {
                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, [System.String], $attributeCollection)

                        break
                    }

                    'choice|multichoice'
                    {
                        $choiceNodes = $node.ChildNodes
                        $setValues = New-Object -TypeName System.String[] -ArgumentList $choiceNodes.Count
                        $i = 0

                        foreach ($choiceNode in $choiceNodes)
                        {
                            $setValues[$i++] = $choiceNode.value
                        }

                        $validateSetAttr = New-Object -TypeName System.Management.Automation.ValidateSetAttribute -ArgumentList $setValues
                        $attributeCollection.Add($validateSetAttr)

                        if ($type -eq 'multichoice')
                        {
                            $type = [System.String[]]
                        }
                        else
                        {
                            $type = [System.String]
                        }

                        $param = [System.Management.Automation.RuntimeDefinedParameter]::new($name, $type, $attributeCollection)

                        break
                    }

                    default
                    {
                        throw "Unrecognized Parameter Type $type for attribute $name."
                    }
                }

                $paramDictionary.Add($name, $param)
            }
        }
        catch
        {
            Write-Warning "Error processing Dynamic Parameters. $($_.Exception.Message)"
        }
        finally
        {
            $ErrorActionPreference = $previousErrorActionPreference
        }

        $paramDictionary
    }

    end
    {
        # Clone the the bound parameters.
        $plasterParameter = @{} + $PSBoundParameters

        $null = $plasterParameter.Remove('Sample')

        $sampleTemplateFolder = Join-Path -Path 'Templates' -ChildPath $Sample
        $templatePath = Join-Path -Path $MyInvocation.MyCommand.Module.ModuleBase -ChildPath $sampleTemplateFolder

        $plasterParameter.Add('TemplatePath', $templatePath)

        if (-not $plasterParameter.ContainsKey('DestinationPath'))
        {
            $plasterParameter['DestinationPath'] = $DestinationPath
        }

        Invoke-Plaster @plasterParameter
    }
}
#EndRegion './Public/Add-Sample.ps1' 230
#Region './Public/Convert-SamplerHashtableToString.ps1' 0

<#
    .SYNOPSIS
        Converts an Hashtable to its string representation, recursively.

    .DESCRIPTION
        Convert an Hashtable to a string representation.
        For instance, this hashtable:
        @{a=1;b=2; c=3; d=@{dd='abcd'}}
        Becomes:
        a=1; b=2; c=3; d={dd=abcd}

    .PARAMETER Hashtable
        Hashtable to convert to string.

    .EXAMPLE
        Convert-SamplerhashtableToString -Hashtable @{a=1;b=2; c=3; d=@{dd='abcd'}}

    .NOTES
        This command is not specific to Sampler projects, but is named that way
        to avoid conflict with other modules.
#>
function Convert-SamplerHashtableToString
{
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $Hashtable
    )
    $values = @()
    foreach ($pair in $Hashtable.GetEnumerator())
    {
        if ($pair.Value -is [System.Array])
        {
            $str = "$($pair.Key)=($($pair.Value -join ","))"
        }
        elseif ($pair.Value -is [System.Collections.Hashtable])
        {
            $str = "$($pair.Key)={$(Convert-SamplerHashtableToString -Hashtable $pair.Value)}"
        }
        else
        {
            $str = "$($pair.Key)=$($pair.Value)"
        }
        $values += $str
    }

    [array]::Sort($values)
    return ($values -join "; ")
}
#EndRegion './Public/Convert-SamplerHashtableToString.ps1' 52
#Region './Public/Get-BuildVersion.ps1' 0

<#
    .SYNOPSIS
        Calculates or retrieves the version of the Repository.

    .DESCRIPTION
        Attempts to retrieve the version associated with the repository or the module within
        the repository.
        If the Version is not provided, the preferred way is to use GitVersion if available,
        but alternatively it will locate a module manifest in the source folder and read its version.

    .PARAMETER ModuleManifestPath
        Path to the Module Manifest that should determine the version if GitVersion is not available.

    .PARAMETER ModuleVersion
        Provide the Version to be splitted and do not rely on GitVersion or the Module's manifest.

    .EXAMPLE
        Get-BuildVersion -ModuleManifestPath source\MyModule.psd1

#>
function Get-BuildVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleManifestPath,

        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    if ([System.String]::IsNullOrEmpty($ModuleVersion))
    {
        Write-Verbose -Message 'Module version is not determined yet. Evaluating methods to get module version.'

        if ((Get-Command -Name 'gitversion' -ErrorAction 'SilentlyContinue'))
        {
            Write-Verbose -Message 'Using the version from GitVersion.'

            $ModuleVersion = (gitversion | ConvertFrom-Json -ErrorAction 'Stop').NuGetVersionV2
        }
        else
        {
            Write-Verbose -Message (
                "GitVersion is not installed. Trying to use the version from module manifest in path '{0}'." -f $ModuleManifestPath
            )

            $moduleInfo = Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'

            $ModuleVersion = $moduleInfo.ModuleVersion

            if ($moduleInfo.PrivateData.PSData.Prerelease)
            {
                $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
            }
        }
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}
#EndRegion './Public/Get-BuildVersion.ps1' 72
#Region './Public/Get-BuiltModuleVersion.ps1' 0

<#
    .SYNOPSIS
        Get the module version from the module built by Sampler.

    .DESCRIPTION
        Will read the ModuleVersion and PrivateData.PSData.Prerelease tag of the Module Manifest
        that has been built by Sampler, by looking into the OutputDirectory where the Project's
        Module should have been built.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .EXAMPLE
        Get-BuiltModuleVersion -OutputDirectory 'output' -ProjectName Sampler

#>
function Get-BuiltModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory
    )

    $BuiltModuleManifestPath = Get-SamplerBuiltModuleManifest @PSBoundParameters

    Write-Verbose -Message (
        "Get the module version from module manifest in path '{0}'." -f $BuiltModuleManifestPath
    )

    $moduleInfo = Import-PowerShellDataFile -Path $BuiltModuleManifestPath -ErrorAction 'Stop'

    $ModuleVersion = $moduleInfo.ModuleVersion

    if ($moduleInfo.PrivateData.PSData.Prerelease)
    {
        $ModuleVersion = $ModuleVersion + '-' + $moduleInfo.PrivateData.PSData.Prerelease
    }

    $moduleVersionParts = Split-ModuleVersion -ModuleVersion $ModuleVersion

    Write-Verbose -Message (
        "Current module version is '{0}'." -f $moduleVersionParts.ModuleVersion
    )

    return $moduleVersionParts.ModuleVersion
}
#EndRegion './Public/Get-BuiltModuleVersion.ps1' 83
#Region './Public/Get-ClassBasedResourceName.ps1' 0

<#
    .SYNOPSIS
        Get the Names of the Class-based DSC Resources defined in a file using AST.

    .DESCRIPTION
        This command returns all Class-based Resource Names in a file,
        by parsing the file and looking for classes with the [DscResource()] attribute.

        For MOF-based DSC Resources, look at the `Get-MofSchemaName` function.

    .PARAMETER Path
        Path of the file to parse and search the Class-Based DSC Resources.

    .EXAMPLE
        Get-ClassBasedResourceName -Path source/Classes/MyDscResource.ps1

        Get-ClassBasedResourceName -Path (Join-Path -Path (Get-Module MyResourceModule).ModuleBase -ChildPath (Get-Module MyResourceModule).RootModule)

#>
function Get-ClassBasedResourceName
{
   [CmdletBinding()]
   [OutputType([String[]])]
   param
   (
       [Parameter(Mandatory = $true)]
       [Alias('FilePath')]
       [System.String]
       $Path
   )

   $ast = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$null, [ref]$null)

   $classDefinition = $ast.FindAll(
       {
           ($args[0].GetType().Name -like "TypeDefinitionAst") -and `
           ($args[0].Attributes.TypeName.Name -contains 'DscResource')
       },
       $true
   )

   return $classDefinition.Name

}
#EndRegion './Public/Get-ClassBasedResourceName.ps1' 46
#Region './Public/Get-CodeCoverageThreshold.ps1' 0

<#
    .SYNOPSIS
        Gets the CodeCoverageThreshod from Runtime parameter or from BuildInfo.

    .DESCRIPTION
        This function will override the CodeCoverageThreshold by the value
        provided at runtime if any.

    .PARAMETER RuntimeCodeCoverageThreshold
        Runtime value for the Pester CodeCoverageThreshold (can be $null).

    .PARAMETER BuildInfo
        BuildInfo object as defined by the Build.yml.

    .EXAMPLE
        Get-CodeCoverageThreshold -RuntimeCodeCoverageThreshold 0

#>
function Get-CodeCoverageThreshold
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [System.String]
        [AllowNull()]
        $RuntimeCodeCoverageThreshold,

        [Parameter()]
        [PSObject]
        $BuildInfo
    )

    # If no codeCoverageThreshold configured at runtime, look for BuildInfo settings.
    if ([String]::IsNullOrEmpty($RuntimeCodeCoverageThreshold))
    {
        if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageThreshold'))
        {
            $codeCoverageThreshold = $BuildInfo.Pester.CodeCoverageThreshold
            Write-Debug -Message "Loaded Code Coverage Threshold from Config file: $codeCoverageThreshold %."
        }
        else
        {
            $codeCoverageThreshold = 0
            Write-Debug -Message "No code coverage threshold value found (param nor config), using the default value."
        }
    }
    else
    {
        $codeCoverageThreshold = [int] $RuntimeCodeCoverageThreshold
        Write-Debug -Message "Loading CodeCoverage Threshold from Parameter ($codeCoverageThreshold %)."
    }

    return $codeCoverageThreshold
}
#EndRegion './Public/Get-CodeCoverageThreshold.ps1' 58
#Region './Public/Get-MofSchemaName.ps1' 0

<#
    .SYNOPSIS
        Gets the Name and Friendly Name of MOF-Based resources from their Schemas.

    .DESCRIPTION
        This function looks within a DSC resource's .MOF schema to find the name and
        friendly name of the class.

    .PARAMETER Path
        Path to the DSC Resource Schema MOF.

    .EXAMPLE
        Get-MofSchemaName -Path Source/DSCResources/MyResource/MyResource.schema.mof

#>
function Get-MofSchemaName
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [System.String]
        $Path
    )

    begin
    {
        $temporaryPath = $null

        # Determine the correct $env:TEMP drive
        switch ($true)
        {
            (-not (Test-Path -Path variable:IsWindows) -or $IsWindows)
            {
                # Windows PowerShell or PowerShell 6+
                $temporaryPath = $env:TEMP
            }

            $IsMacOS
            {
                $temporaryPath = $env:TMPDIR

                throw 'NotImplemented: Currently there is an issue using the type [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache] on macOS. See issue https://github.com/PowerShell/PowerShell/issues/5970 and issue https://github.com/PowerShell/MMI/issues/33.'
            }

            $IsLinux
            {
                $temporaryPath = '/tmp'
            }

            default
            {
                throw 'Cannot set the temporary path. Unknown operating system.'
            }
        }

        $tempFilePath = Join-Path -Path $temporaryPath -ChildPath "DscMofHelper_$((New-Guid).Guid).tmp"
    }

    process
    {
        #region Workaround for OMI_BaseResource inheritance not resolving.
        $rawContent = (Get-Content -Path $Path -Raw) -replace '\s*:\s*OMI_BaseResource'
        Set-Content -LiteralPath $tempFilePath -Value $rawContent -ErrorAction 'Stop'

        # .NET methods don't like PowerShell drives
        $tempFilePath = Convert-Path -Path $tempFilePath

        #endregion

        try
        {
            $exceptionCollection = [System.Collections.ObjectModel.Collection[System.Exception]]::new()
            $moduleInfo = [System.Tuple]::Create('Module', [System.Version] '1.0.0')

            $class = [Microsoft.PowerShell.DesiredStateConfiguration.Internal.DscClassCache]::ImportClasses(
                $tempFilePath, $moduleInfo, $exceptionCollection
            )
        }
        catch
        {
            Remove-Item -LiteralPath $tempFilePath -Force
            throw "Failed to import classes from file $Path. Error $_"
        }

        <#
            For most efficiency, we re-use the same temp file.
            We need to be sure that the file is empty before the next import.
            If no, we risk to import the same class twice.
        #>
        Set-Content -LiteralPath $tempFilePath -Value ''

        return @{
            Name = $class.CimClassName
            FriendlyName = ($class.Cimclassqualifiers | Where-Object -FilterScript { $_.Name -eq 'FriendlyName' }).Value
        }
    }

    end
    {
        Remove-Item -LiteralPath $tempFilePath -Force
    }
}
#EndRegion './Public/Get-MofSchemaName.ps1' 109
#Region './Public/Get-OperatingSystemShortName.ps1' 0

<#
    .SYNOPSIS
        Returns the Platform name.

    .DESCRIPTION
        Gets whether the platform is Windows, Linux or MacOS.

    .EXAMPLE
        Get-OperatingSystemShortName # no Parameter needed

    .NOTES
        General notes
#>
function Get-OperatingSystemShortName
{
    [CmdletBinding()]
    param ()

    $osShortName = if ($IsWindows -or $PSVersionTable.PSVersion.Major -le 5)
    {
        'Windows'
    }
    elseif ($IsMacOS)
    {
        'MacOS'
    }
    else
    {
        'Linux'
    }

    return $osShortName
}
#EndRegion './Public/Get-OperatingSystemShortName.ps1' 35
#Region './Public/Get-PesterOutputFileFileName.ps1' 0

<#
    .SYNOPSIS
        Gets a descriptive file name to be used as Pester Output file name.

    .DESCRIPTION
        Creates a file name to be used as Pester Output xml file composed like so:
        "${ProjectName}_v${ModuleVersion}.${OsShortName}.${PowerShellVersion}.xml"

    .PARAMETER ProjectName
        Name of the Project or module being built.

    .PARAMETER ModuleVersion
        Module Version currently defined (including pre-release but without the metadata).

    .PARAMETER OsShortName
        Platform name either Windows, Linux, or MacOS.

    .PARAMETER PowerShellVersion
        Version of PowerShell the tests have been running on.

    .EXAMPLE
        Get-PesterOutputFileFileName -ProjectName 'Sampler' -ModuleVersion 0.110.4-preview001 -OsShortName Windows -PowerShellVersion 5.1

    .NOTES
        General notes
#>
function Get-PesterOutputFileFileName
{
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $ProjectName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleVersion,

        [Parameter(Mandatory = $true)]
        [System.String]
        $OsShortName,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PowerShellVersion
    )

    return '{0}_v{1}.{2}.{3}.xml' -f $ProjectName, $ModuleVersion, $OsShortName, $PowerShellVersion
}
#EndRegion './Public/Get-PesterOutputFileFileName.ps1' 51
#Region './Public/Get-SamplerAbsolutePath.ps1' 0

<#
    .SYNOPSIS
        Gets the absolute value of a path, that can be relative to another folder
        or the current Working Directory `$PWD` or Drive.

    .DESCRIPTION
        This function will resolve the Absolute value of a path, whether it's
        potentially relative to another path, relative to the current working
        directory, or it's provided with an absolute Path.

        The Path does not need to exist, but the command will use the right
        [System.Io.Path]::DirectorySeparatorChar for the OS, and adjust the
        `..` and `.` of a path by removing parts of a path when needed.

    .PARAMETER Path
        Relative or Absolute Path to resolve, can also be $null/Empty and will
        return the RelativeTo absolute path.
        It can be Absolute but relative to the current drive: i.e. `/Windows`
        would resolve to `C:\Windows` on most Windows systems.

    .PARAMETER RelativeTo
        Path to prepend to $Path if $Path is not Absolute.
        If $RelativeTo is not absolute either, it will first be resolved
        using [System.Io.Path]::GetFullPath($RelativeTo) before
        being pre-pended to $Path.

    .EXAMPLE
        Get-SamplerAbsolutePath -Path '/src' -RelativeTo 'C:\Windows'
        # C:\src

    .EXAMPLE
        Get-SamplerAbsolutePath -Path 'MySubFolder' -RelativeTo '/src'
        # C:\src\MySubFolder

    .NOTES
        When the root drive is omitted on Windows, the path is not considered absolute.
        `Split-Path -IsAbsolute -Path '/src/`
        # $false
#>
function Get-SamplerAbsolutePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter()]
        [AllowNull()]
        [System.String]
        $Path,

        [Parameter()]
        [System.String]
        $RelativeTo
    )

    if (-not [System.Io.Path]::IsPathRooted($RelativeTo))
    {
        # If the path is not rooted it's a relative path
        $RelativeTo = Join-Path -Path ([System.Io.Path]::GetFullPath('.')) -ChildPath $RelativeTo
    }
    elseif (-not (Split-Path -IsAbsolute -Path $RelativeTo) -and [System.Io.Path]::IsPathRooted($RelativeTo))
    {
        # If the path is not Absolute but is rooted, it's starts with / or \ on Windows.
        # Add the Current PSDrive root
        $CurrentDriveRoot = $pwd.drive.root
        $RelativeTo = Join-Path -Path $CurrentDriveRoot -ChildPath $RelativeTo
    }

    if ($PSVersionTable.PSVersion.Major -ge 7)
    {
        # This behave differently in 5.1 where * are forbidden. :(
        $RelativeTo = [System.io.Path]::GetFullPath($RelativeTo)
    }

    if (-not [System.Io.Path]::IsPathRooted($Path))
    {
        # If the path is not rooted it's a relative path (relative to $RelativeTo)
        $Path = Join-Path -Path $RelativeTo -ChildPath $Path
    }
    elseif (-not (Split-Path -IsAbsolute -Path $Path) -and [System.Io.Path]::IsPathRooted($Path))
    {
        # If the path is not Absolute but is rooted, it's starts with / or \ on Windows.
        # Add the Current PSDrive root
        $CurrentDriveRoot = $pwd.drive.root
        $Path = Join-Path -Path $CurrentDriveRoot -ChildPath $Path
    }
    # Else The Path is Absolute

    if ($PSVersionTable.PSVersion.Major -ge 7)
    {
        # This behave differently in 5.1 where * are forbidden. :(
        $Path = [System.io.Path]::GetFullPath($Path)
    }

    return $Path
}
#EndRegion './Public/Get-SamplerAbsolutePath.ps1' 98
#Region './Public/Get-SamplerBuiltModuleBase.ps1' 0

<#
    .SYNOPSIS
        Get the ModuleBase of a module built with Sampler (directory where the module
        manifest is).

    .DESCRIPTION
        Based on a project's configuration of OutputDirectory, BuiltModuleSubdirectory,
        ModuleName and whether the built module is within a VersionedOutputDirectory;
        this function will resolve the expected ModuleBase of that Module.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleVersion
        Allows to specify a specific ModuleVersion to search the ModuleBase if known.
        If the ModuleVersion is not known but the VersionedOutputDirectory is set to $true,
        a wildcard (*) will be used so that the path can be resolved by Get-Item or similar commands.

    .EXAMPLE
        Get-SamplerBuiltModuleBase -OutputDirectory C:\src\output -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion 3.1.2-preview001
        # C:\src\output\Module\stuff\3.1.2

#>
function Get-SamplerBuiltModuleBase
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [ValidateNotNull()]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory,

        [Parameter()]
        [System.String]
        $ModuleVersion = '*'
    )

    $BuiltModuleOutputPath = Get-SamplerAbsolutePath -Path $BuiltModuleSubdirectory -RelativeTo $OutputDirectory
    $BuiltModulePath = Get-SamplerAbsolutePath -Path $ModuleName -RelativeTo $BuiltModuleOutputPath

    if ($VersionedOutputDirectory -or ($PSBoundParameters.ContainsKey('ModuleVersion') -and $ModuleVersion -ne '*'))
    {
        if ($ModuleVersion -eq '*' -or [System.String]::IsNullOrEmpty($ModuleVersion))
        {
            $ModuleVersion = '*'
        }
        else
        {
            $ModuleVersion = (Split-ModuleVersion -ModuleVersion $ModuleVersion).Version
        }

        $BuiltModuleBase = Get-SamplerAbsolutePath -Path $ModuleVersion -RelativeTo $BuiltModulePath
    }
    else
    {
        $BuiltModuleBase = $BuiltModulePath
    }

    return $BuiltModuleBase
}
#EndRegion './Public/Get-SamplerBuiltModuleBase.ps1' 95
#Region './Public/Get-SamplerBuiltModuleManifest.ps1' 0

<#
    .SYNOPSIS
        Get the module manifest from a module built by Sampler.

    .DESCRIPTION
        Based on a project's OutputDirectory, BuiltModuleSubdirectory,
        ModuleName and whether the built module is within a VersionedOutputDirectory;
        this function will resolve the expected ModuleManifest of that Module.

    .PARAMETER OutputDirectory
        Output directory (usually as defined by the Project).
        By default it is set to 'output' in a Sampler project.

    .PARAMETER BuiltModuleSubdirectory
        Sub folder where you want to build the Module to (instead of $OutputDirectory/$ModuleName).
        This is especially useful when you want to build DSC Resources, but you don't want the
        `Get-DscResource` command to find several instances of the same DSC Resources because
        of the overlapping $Env:PSmodulePath (`$buildRoot/output` for the built module and `$buildRoot/output/RequiredModules`).

        In most cases I would recommend against setting $BuiltModuleSubdirectory.

    .PARAMETER ModuleName
        Name of the Module to retrieve the version from its manifest (See Get-SamplerProjectName).

    .PARAMETER VersionedOutputDirectory
        Whether the Module is built with its versioned Subdirectory, as you would see it on a System.
        For instance, if VersionedOutputDirectory is $true, the built module's ModuleBase would be: `output/MyModuleName/2.0.1/`

    .PARAMETER ModuleVersion
        Allows to specify a specific ModuleVersion to search the ModuleBase if known.
        If the ModuleVersion is not known but the VersionedOutputDirectory is set to $true,
        a wildcard (*) will be used so that the path can be resolved by Get-Item or similar commands.

    .EXAMPLE
        Get-SamplerBuiltModuleManifest -OutputDirectory C:\src\output -BuiltModuleSubdirectory 'Module' -ModuleName 'stuff' -ModuleVersion 3.1.2-preview001
        # C:\src\output\Module\stuff\3.1.2\stuff.psd1

    .NOTES
        See Get-SamplerBuiltModuleBase as this command only extrapolates the Manifest file from the
        Build module base, using the ModuleName parameter.
#>
function Get-SamplerBuiltModuleManifest
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.String]
        $OutputDirectory,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $BuiltModuleSubdirectory,

        [Parameter(Mandatory = $true)]
        [Alias('ProjectName')]
        [ValidateNotNull()]
        [System.String]
        $ModuleName,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $VersionedOutputDirectory,

        [Parameter()]
        [System.String]
        $ModuleVersion = '*'
    )

    $BuiltModuleBase = Get-SamplerBuiltModuleBase @PSBoundParameters

    Get-SamplerAbsolutePath -Path ('{0}.psd1' -f $ModuleName) -RelativeTo $BuiltModuleBase
}
#EndRegion './Public/Get-SamplerBuiltModuleManifest.ps1' 78
#Region './Public/Get-SamplerCodeCoverageOutputFile.ps1' 0

<#
    .SYNOPSIS
        Resolves the CodeCoverage output file path from the project's BuildInfo.

    .DESCRIPTION
        When the Pester CodeCoverageOutputFile is configured in the
        buildinfo (aka Build.yml), this function will expand the path
        (if it contains variables), and resolve to it's absolute path if needed.

    .PARAMETER BuildInfo
        The BuildInfo object represented in the Build.yml.

    .PARAMETER PesterOutputFolder
        The Pester output folder (that can be overridden at runtime).

    .EXAMPLE
        Get-SamplerCodeCoverageOutputFile -BuildInfo $buildInfo -PesterOuputFolder 'C:\src\MyModule\Output\testResults

#>
function Get-SamplerCodeCoverageOutputFile
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo,

        [Parameter(Mandatory = $true)]
        [System.String]
        $PesterOutputFolder
    )

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFile'))
    {
        $codeCoverageOutputFile = $executioncontext.invokecommand.expandstring($BuildInfo.Pester.CodeCoverageOutputFile)

        if (-not (Split-Path -IsAbsolute $codeCoverageOutputFile))
        {
            $codeCoverageOutputFile = Join-Path -Path $PesterOutputFolder -ChildPath $codeCoverageOutputFile

            Write-Debug -Message "Absolute path to code coverage output file is $codeCoverageOutputFile."
        }
    }
    else
    {
        $codeCoverageOutputFile = $null
    }

    return $codeCoverageOutputFile
}
#EndRegion './Public/Get-SamplerCodeCoverageOutputFile.ps1' 53
#Region './Public/Get-SamplerCodeCoverageOutputFileEncoding.ps1' 0

<#
    .SYNOPSIS
        Returns the Configured encoding for Pester code coverage file from BuildInfo.

    .DESCRIPTION
        This function returns the CodeCoverageOutputFileEncoding (Pester v5+) as
        configured in the BuildInfo (build.yml).

    .PARAMETER BuildInfo
        Build Configuration object as defined in the Build.yml.

    .EXAMPLE
        Get-SamplerCodeCoverageOutputFileEncoding -BuildInfo $buildInfo

#>
function Get-SamplerCodeCoverageOutputFileEncoding
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [PSObject]
        $BuildInfo
    )

    if ($BuildInfo.ContainsKey('Pester') -and $BuildInfo.Pester.ContainsKey('CodeCoverageOutputFileEncoding'))
    {
        $codeCoverageOutputFileEncoding = $BuildInfo.Pester.CodeCoverageOutputFileEncoding
    }
    else
    {
        $codeCoverageOutputFileEncoding = $null
    }

    return $codeCoverageOutputFileEncoding
}
#EndRegion './Public/Get-SamplerCodeCoverageOutputFileEncoding.ps1' 38
#Region './Public/Get-SamplerModuleInfo.ps1' 0

<#
    .SYNOPSIS
        Loads the PowerShell data file of a module manifest.

    .DESCRIPTION
        This function loads a psd1 (usually a module manifest), and return the hashtable.
        This implementation works around the issue where Windows PowerShell version have issues
        with the pwsh $Env:PSModulePath such as in vscode with the vscode powershell extension.

    .PARAMETER ModuleManifestPath
        Path to the ModuleManifest to load. This will not use Import-Module because the
        module may not be finished building, and might be missing some information to make
        it a valid module manifest.

    .EXAMPLE
        Get-SamplerModuleInfo -ModuleManifestPath C:\src\MyProject\output\MyProject\MyProject.psd1

#>
function Get-SamplerModuleInfo
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [ValidateNotNull()]
        [System.String]
        $ModuleManifestPath
    )

    $isImportPowerShellDataFileAvailable = Get-Command -Name Import-PowerShellDataFile -ErrorAction SilentlyContinue

    if ($PSversionTable.PSversion.Major -le 5 -and -not $isImportPowerShellDataFileAvailable)
    {
        Import-Module -Name Microsoft.PowerShell.Utility -RequiredVersion 3.1.0.0
    }

    Import-PowerShellDataFile -Path $ModuleManifestPath -ErrorAction 'Stop'
}
#EndRegion './Public/Get-SamplerModuleInfo.ps1' 42
#Region './Public/Get-SamplerModuleRootPath.ps1' 0

<#
    .SYNOPSIS
        Gets the absolute ModuleRoot path (the psm1) of a module.

    .DESCRIPTION
        This function reads the module manifest (.psd1) and if the ModuleRoot property
        is defined, it will resolve its absolute path based on the ModuleManifest's Path.

        If no ModuleRoot is defined, then this function will return $null.

    .PARAMETER ModuleManifestPath
        The path (relative to the current working directory or absolute) to the ModuleManifest to
        read to find the ModuleRoot.

    .EXAMPLE
        Get-SamplerModuleRootPath -ModuleManifestPath C:\src\MyModule\output\MyModule\2.3.4\MyModule.psd1
        # C:\src\MyModule\output\MyModule\2.3.4\MyModule.psm1

#>
function Get-SamplerModuleRootPath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [ValidateNotNull()]
        [System.String]
        $ModuleManifestPath
    )

    $moduleInfo = Get-SamplerModuleInfo @PSBoundParameters

    if ($moduleInfo.Keys -contains 'RootModule')
    {
        Get-SamplerAbsolutePath -Path $moduleInfo.RootModule -RelativeTo (Split-Path -Parent -Path $ModuleManifestPath)
    }
    else
    {
        return $null
    }
}
#EndRegion './Public/Get-SamplerModuleRootPath.ps1' 45
#Region './Public/Get-SamplerProjectName.ps1' 0

<#
    .SYNOPSIS
        Gets the Project Name based on the ModuleManifest if Available.

    .DESCRIPTION
        Finds the Module Manifest through `Get-SamplerProjectModuleManifest`
        and deduce ProjectName based on the BaseName of that manifest.

    .PARAMETER BuildRoot
        BuildRoot of the Sampler project to search the Module manifest from.

    .EXAMPLE
        Get-SamplerProjectName -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerProjectName
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    return (Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot).BaseName
}
#EndRegion './Public/Get-SamplerProjectName.ps1' 30
#Region './Public/Get-SamplerSourcePath.ps1' 0

<#
    .SYNOPSIS
        Gets the project's source Path based on the ModuleManifest location.

    .DESCRIPTION
        By finding the ModuleManifest of the project using `Get-SamplerProjectModuleManifest`
        this function assumes that the source folder is the parent folder of
        that module manifest.
        This allows the source folder to be src, source, or the Module name's, without
        hardcoding the name.

    .PARAMETER BuildRoot
        BuildRoot of the Sampler project to search the Module manifest from.

    .EXAMPLE
        Get-SamplerSourcePath -BuildRoot 'C:\src\MyModule'

#>
function Get-SamplerSourcePath
{
    [CmdletBinding()]
    [OutputType([System.String])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $BuildRoot
    )

    return (Get-SamplerProjectModuleManifest -BuildRoot $BuildRoot).Directory.FullName
}
#EndRegion './Public/Get-SamplerSourcePath.ps1' 33
#Region './Public/Merge-JaCoCoReport.ps1' 0

<#
    .SYNOPSIS
        Merge two JaCoCoReports into one.

    .DESCRIPTION
        When you run tests independently for the same module, you may want to
        get a unified report of all the code paths that were tested.
        For instance, you want to get a unified report when the runs
        where done on Linux and Windows.

        This function helps merge the results of two runs into one file.
        If you have more than two reports, keep merging them.

    .PARAMETER OriginalDocument
        One of the JaCoCoReports you would like to merge.

    .PARAMETER MergeDocument
        Second JaCoCoReports you would like to merge with the other one.

    .EXAMPLE
        Merge-JaCoCoReport -OriginalDocument 'C:\src\MyModule\Output\JaCoCoRun_linux.xml' -MergeDocument 'C:\src\MyModule\Output\JaCoCoRun_windows.xml'

    .NOTES
        See also Update-JaCoCoStatistic
        Thanks to Yorick (@ykuijs) for this great feature!
#>
function Merge-JaCoCoReport
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $OriginalDocument,

        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $MergeDocument
    )

    foreach ($mPackage in $MergeDocument.report.package)
    {
        Write-Verbose "  Processing package: $($mPackage.Name)"

        $oPackage = $OriginalDocument.report.package | Where-Object { $_.Name -eq $mPackage.Name }

        <#
            TODO: This only supports merging whole packages. It should also support
            merging individual 'class' elements and its accompanied 'sourcefile'
            element into an already existing package. I think it even possible
            that it must support merging individual 'method' elements inside a
            'class' element too.
        #>
        if ($null -ne $oPackage)
        {
            <#
                'package' element already exist, add or update 'line' element for
                the correct 'sourcefile' element inside the 'package' element.
            #>
            foreach ($mSourcefile in $mPackage.sourcefile)
            {
                Write-Verbose "    Processing sourcefile: $($mSourcefile.Name)"

                foreach ($mPackageLine in $mSourcefile.line)
                {
                    $oSourcefile = $oPackage.sourcefile | Where-Object { $_.name -eq $mSourcefile.name }
                    $oPackageLine = $oSourcefile.line | Where-Object { $_.nr -eq $mPackageLine.nr }

                    if ($null -eq $oPackageLine)
                    {
                        # Missed line in origin, covered in merge
                        Write-Verbose "      Adding line: $($mPackageLine.nr)"
                        $null = $oPackage.sourcefile.AppendChild($oPackage.sourcefile.OwnerDocument.ImportNode($mPackageLine, $true))
                        continue
                    }

                    if (($oPackageLine.ci -eq 0) -and ($oPackageLine.mi -ne 0) -and `
                        ($mPackageLine.ci -ne 0) -and ($mPackageLine.mi -eq 0))
                    {
                        # Missed line in origin, covered in merge
                        Write-Verbose "      Updating missed line: $($mPackageLine.nr)"
                        $oPackageLine.ci = $mPackageLine.ci
                        $oPackageLine.mi = $mPackageLine.mi
                        continue
                    }

                    if ($oPackageLine.ci -lt $mPackageLine.ci)
                    {
                        # Missed line in origin, covered in merge
                        Write-Verbose "      Updating line: $($mPackageLine.nr)"
                        $oPackageLine.ci = $mPackageLine.ci
                        $oPackageLine.mi = $mPackageLine.mi
                        continue
                    }
                }
            }
        }
        else
        {
            # New package, does not exist in origin. Add package.
            Write-Verbose "    Package '$($mPackage.Name)' does not exist in original file. Adding..."

            <#
                Must import the node with child elements first since it belongs
                to another XML document.
            #>
            $packageElementToMerge = $OriginalDocument.ImportNode($mPackage, $true)

            <#
                Append the 'package' element to the 'report' element.
                The second array item in 'report' property is the XmlElement object.
            #>
            $OriginalDocument.report[1].AppendChild($packageElementToMerge) | Out-Null
        }
    }

    <#
        The counters at the 'report' element level need to be moved at the end
        of the document to comply with the DTD. Select out the report element here
    #>
    $elementToMove = Select-XML -Xml $OriginalDocument -XPath '/report/counter'

    if ($elementToMove)
    {
        $elementToMove | ForEach-Object -Process {
            $elementToMove.Node.ParentNode.AppendChild($_.Node) | Out-Null
        }
    }

    return $OriginalDocument
}
#EndRegion './Public/Merge-JaCoCoReport.ps1' 134
#Region './Public/New-SampleModule.ps1' 0

<#
    .SYNOPSIS
        Create a module scaffolding and add samples & build pipeline.

    .DESCRIPTION
        New-SampleModule helps you bootstrap your PowerShell module project by
        creating a the folder structure of your module, and optionally add the
        pipeline files to help with compiling the module, publishing to PSGallery
        and GitHub and testing quality and style such as per the DSC Community
        guildelines.

    .PARAMETER DestinationPath
        Destination of your module source root folder, defaults to the current directory ".".
        We assume that your current location is the module folder, and within this folder we
        will find the source folder, the tests folder and other supporting files.

    .PARAMETER ModuleType
        Specifies the type of module to create. The default value is 'SimpleModule'.
        Preset of module you would like to create:
            - CompleteSample
            - SimpleModule
            - SimpleModule_NoBuild
            - dsccommunity

    .PARAMETER ModuleAuthor
        The author of module that will be populated in the Module Manifest and will show in the Gallery.

    .PARAMETER ModuleName
        The Name of your Module.

    .PARAMETER ModuleDescription
        The Description of your Module, to be used in your Module manifest.

    .PARAMETER CustomRepo
        The Custom PS repository if you want to use an internal (private) feed to pull for dependencies.

    .PARAMETER ModuleVersion
        Version you want to set in your Module Manifest. If you follow our approach, this will be updated during compilation anyway.

    .PARAMETER LicenseType
        Type of license you would like to add to your repository. We recommend MIT for Open Source projects.

    .PARAMETER SourceDirectory
        How you would like to call your Source repository to differentiate from the output and the tests folder. We recommend to call it 'source',
        and the default value is 'source'.

    .PARAMETER Features
        If you'd rather select specific features from this template to build your module, use this parameter instead.

    .EXAMPLE
        C:\src> New-SampleModule -DestinationPath . -ModuleType CompleteSample -ModuleAuthor "Gael Colas" -ModuleName MyModule -ModuleVersion 0.0.1 -ModuleDescription "a sample module" -LicenseType MIT -SourceDirectory Source

    .NOTES
        See Add-Sample to add elements such as functions (private or public), tests, DSC Resources to your project.
#>
function New-SampleModule
{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSReviewUnusedParameter', '')]
    [CmdletBinding(DefaultParameterSetName = 'ByModuleType')]
    [OutputType([System.Void])]
    param (
        [Parameter(Mandatory = $true)]
        [Alias('Path')]
        [System.String]
        $DestinationPath,

        [Parameter(ParameterSetName = 'ByModuleType')]
        [string]
        [ValidateSet('SimpleModule', 'CompleteSample', 'SimpleModule_NoBuild', 'newDscCommunity', 'dsccommunity')]
        $ModuleType = 'SimpleModule',

        [Parameter()]
        [System.String]
        $ModuleAuthor = $env:USERNAME,

        [Parameter(Mandatory = $true)]
        [System.String]
        $ModuleName,

        [Parameter()]
        [AllowNull()]
        [System.String]
        $ModuleDescription,

        [Parameter()]
        [System.String]
        $CustomRepo = 'PSGallery',

        [Parameter()]
        [System.String]
        $ModuleVersion = '0.0.1',

        [Parameter()]
        [System.String]
        [ValidateSet('MIT','Apache','None')]
        $LicenseType = 'MIT',

        [Parameter()]
        [System.String]
        [ValidateSet('source','src')]
        $SourceDirectory = 'source',

        [Parameter(ParameterSetName = 'ByFeature')]
        [ValidateSet(
            'All',
            'Enum',
            'Classes',
            'DSCResources',
            'ClassDSCResource',
            'SampleScripts',
            'git',
            'Gherkin',
            'UnitTests',
            'ModuleQuality',
            'Build',
            'AppVeyor',
            'TestKitchen'
            )]
        [System.String[]]
        $Features
    )

    $templateSubPath = 'Templates/Sampler'
    $samplerBase = $MyInvocation.MyCommand.Module.ModuleBase

    $invokePlasterParam = @{
        TemplatePath = Join-Path -Path $samplerBase -ChildPath $templateSubPath
        DestinationPath   = $DestinationPath
        NoLogo            = $true
        ModuleName        = $ModuleName
    }

    foreach ($paramName in $MyInvocation.MyCommand.Parameters.Keys)
    {
        $paramValue = Get-Variable -Name $paramName -ValueOnly -ErrorAction SilentlyContinue

        # if $paramName is $null, leave it to Plaster to ask the user.
        if ($paramvalue -and -not $invokePlasterParam.ContainsKey($paramName))
        {
            $invokePlasterParam.Add($paramName, $paramValue)
        }
    }

    if ($LicenseType -eq 'none')
    {
        $invokePlasterParam.Remove('LicenseType')
        $invokePlasterParam.add('License', 'false')
    }
    else
    {
        $invokePlasterParam.add('License', 'true')
    }

    Invoke-Plaster @invokePlasterParam
}
#EndRegion './Public/New-SampleModule.ps1' 158
#Region './Public/Split-ModuleVersion.ps1' 0

<#
    .SYNOPSIS
        Parse a SemVer2 Version string.

    .DESCRIPTION
        This function parses a SemVer (semver.org) version string into an object
        with the following properties:
        - Version: The version without tag or metadata, as used by folder versioning in PowerShell modules.
        - PreReleaseString: A Publish-Module compliant prerelease tag (see below).
        - ModuleVersion: The Version and Prerelease tag compliant with Publish-Module.

        For instance, this is a valid SemVer: `1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07`
        The Metadata is stripped: `1.15.0-pr0224-0022`
        The Version is `1.15.0`.
        The prerelease tag is `-pr0224-0022`
        However, Publish-Module (or NuGet/PSGallery) does not support such pre-release,
        so this function only keep the first part `-pr0224`

    .PARAMETER ModuleVersion
        Full SemVer version string with (optional) metadata and prerelease tag to be parsed.

    .EXAMPLE
        Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07'

        # Version PreReleaseString ModuleVersion
        # ------- ---------------- -------------
        # 1.15.0  pr0224           1.15.0-pr0224

#>
function Split-ModuleVersion
{
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    param
    (
        [Parameter()]
        [System.String]
        $ModuleVersion
    )

    <#
        This handles a previous version of the module that suggested to pass
        a version string with metadata in the CI pipeline that can look like
        this: 1.15.0-pr0224-0022+Sha.47ae45eb2cfed02b249f239a7c55e5c71b26ab76.Date.2020-01-07
    #>
    $ModuleVersion = ($ModuleVersion -split '\+', 2)[0]

    $moduleVersion, $preReleaseString = $ModuleVersion -split '-', 2

    <#
        The cmldet Publish-Module does not yet support semver compliant
        pre-release strings. If the prerelease string contains a dash ('-')
        then the dash and everything behind is removed. For example
        'pr54-0012' is parsed to 'pr54'.
    #>
    $validPreReleaseString, $preReleaseStringSuffix = $preReleaseString -split '-'

    if ($validPreReleaseString)
    {
        $fullModuleVersion =  $moduleVersion + '-' + $validPreReleaseString
    }
    else
    {
        $fullModuleVersion =  $moduleVersion
    }

    $moduleVersionParts = [PSCustomObject]@{
        Version          = $moduleVersion
        PreReleaseString = $validPreReleaseString
        ModuleVersion    = $fullModuleVersion
    }

    return $moduleVersionParts
}
#EndRegion './Public/Split-ModuleVersion.ps1' 76
#Region './Public/Update-JaCoCoStatistic.ps1' 0

<#
    .SYNOPSIS
        Update the Statistics of a freshly merged JaCoCoReports.

    .DESCRIPTION
        When you merge two or several JaCoCoReports together
        using the Merge-JaCoCoReport, the calculated statistics
        of the Original document are not updated.

        This Command will re-calculate the JaCoCo statistics and
        update the Document.

        For the Package, Class, Method of all source files and the total it will update:
        - the Instruction Covered
        - the Instruction Missed
        - the Line Covered
        - the Line Missed
        - the Method Covered
        - the Method Missed
        - the Class Covered
        - the Class Missed

    .PARAMETER Document
        JaCoCo report XML document that needs its statistics recalculated.

    .EXAMPLE
        Update-JaCoCoStatistic -Document (Merge-JaCoCoReport $file1 $file2)

    .NOTES
        See also Merge-JaCoCoReport
        Thanks to Yorick (@ykuijs) for this great feature!
#>
function Update-JaCoCoStatistic
{
    [CmdletBinding()]
    [OutputType([System.Xml.XmlDocument])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '')]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Xml.XmlDocument]
        $Document
    )

    Write-Verbose "Start updating statistics!"

    $totalInstructionCovered = 0
    $totalInstructionMissed = 0
    $totalLineCovered = 0
    $totalLineMissed = 0
    $totalMethodCovered = 0
    $totalMethodMissed = 0
    $totalClassCovered = 0
    $totalClassMissed = 0

    foreach ($oPackage in $Document.report.package)
    {
        Write-Verbose "Processing package $($oPackage.name)"

        $packageInstructionCovered = 0
        $packageInstructionMissed = 0
        $packageLineCovered = 0
        $packageLineMissed = 0
        $packageMethodCovered = 0
        $packageMethodMissed = 0
        $packageClassCovered = 0
        $packageClassMissed = 0

        foreach ($oPackageClass in $oPackage.class)
        {
            $classInstructionCovered = 0
            $classInstructionMissed = 0
            $classLineCovered = 0
            $classLineMissed = 0
            $classMethodCovered = 0
            $classMethodMissed = 0

            Write-Verbose "  Processing sourcefile $($oPackageClass.sourcefilename)"
            $oPackageSourcefile = $oPackage.sourcefile | Where-Object -FilterScript { $_.Name -eq $oPackageClass.sourcefilename }

            for ($i = 0; $i -lt ([array]($oPackageClass.method)).Count; $i++)
            {
                $methodInstructionCovered = 0
                $methodInstructionMissed = 0
                $methodLineCovered = 0
                $methodLineMissed = 0
                $methodCovered = 0
                $methodMissed = 0

                $currentMethod = [array]$oPackageClass.method
                $start = $currentMethod[$i].line
                if ($i -ne ($currentMethod.Count - 1))
                {
                    $end   = $currentMethod[$i+1].Line
                    Write-Verbose "    Processing method: $($currentMethod[$i].Name)"
                    [array]$coll = $oPackageSourcefile.line | Where-Object {
                        [int]$_.nr -ge $start -and [int]$_.nr -lt $end
                    }

                    foreach ($line in $coll)
                    {
                        $methodInstructionCovered += $line.ci
                        $methodInstructionMissed += $line.mi
                    }

                    [array]$cov = $coll | Where-Object -FilterScript { $_.ci -ne "0" }
                    $methodLineCovered = $cov.Count
                    [array]$mis = $coll | Where-Object -FilterScript { $_.ci -eq "0" }
                    $methodLineMissed = $mis.Count
                }
                else
                {
                    Write-Verbose "    Processing method: $($currentMethod[$i].Name)"
                    [array]$coll = $oPackageSourcefile.line | Where-Object {
                        [int]$_.nr -ge $start
                    }

                    foreach ($line in $coll)
                    {
                        $methodInstructionCovered += $line.ci
                        $methodInstructionMissed += $line.mi
                    }

                    [array]$cov = $coll | Where-Object -FilterScript { $_.ci -ne "0" }
                    $methodLineCovered = $cov.Count
                    [array]$mis = $coll | Where-Object -FilterScript { $_.ci -eq "0" }
                    $methodLineMissed = $mis.Count
                }

                $classInstructionCovered += $methodInstructionCovered
                $classInstructionMissed += $methodInstructionMissed
                $classLineCovered += $methodLineCovered
                $classLineMissed += $methodLineMissed
                if ($methodInstructionCovered -ne 0)
                {
                    $methodCovered = 1
                    $methodMissed = 0
                    $classMethodCovered++
                }
                else
                {
                    $methodCovered = 0
                    $methodMissed = 1
                    $classMethodMissed++
                }

                # Update Method stats
                $counterInstruction = $currentMethod[$i].counter | Where-Object { $_.type -eq 'INSTRUCTION' }
                $counterInstruction.covered = [string]$methodInstructionCovered
                $counterInstruction.missed = [string]$methodInstructionMissed

                $counterLine = $currentMethod[$i].counter | Where-Object { $_.type -eq 'LINE' }
                $counterLine.covered = [string]$methodLineCovered
                $counterLine.missed = [string]$methodLineMissed

                $counterMethod = $currentMethod[$i].counter | Where-Object { $_.type -eq 'METHOD' }
                $counterMethod.covered = [string]$methodCovered
                $counterMethod.missed = [string]$methodMissed


                Write-Verbose "      Method Instruction Covered : $methodInstructionCovered"
                Write-Verbose "      Method Instruction Missed  : $methodInstructionMissed"
                Write-Verbose "      Method Line Covered        : $methodLineCovered"
                Write-Verbose "      Method Line Missed         : $methodLineMissed"
                Write-Verbose "      Method Covered             : $methodCovered"
                Write-Verbose "      Method Missed              : $methodMissed"
            }

            $packageInstructionCovered += $classInstructionCovered
            $packageInstructionMissed += $classInstructionMissed
            $packageLineCovered += $classLineCovered
            $packageLineMissed += $classLineMissed
            $packageMethodCovered += $classMethodCovered
            $packageMethodMissed += $classMethodMissed

            <#
                JaCoCo considers constructors as well as static initializers as methods,
                so any code run at script level should be considered as the class
                was run.
            #>
            if ($classInstructionCovered -ne 0)
            {
                $packageClassCovered++
                $classClassCovered = 1
                $classClassMissed = 0
            }
            else
            {
                $classClassCovered = 0
                $classClassMissed = 1
            }

            # Update Class stats
            $counterInstruction = $oPackageClass.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
            $counterInstruction.covered = [string]$classInstructionCovered
            $counterInstruction.missed = [string]$classInstructionMissed

            $counterLine = $oPackageClass.counter | Where-Object { $_.type -eq 'LINE' }
            $counterLine.covered = [string]$classLineCovered
            $counterLine.missed = [string]$classLineMissed

            $counterMethod = $oPackageClass.counter | Where-Object { $_.type -eq 'METHOD' }
            $counterMethod.covered = [string]$classMethodCovered
            $counterMethod.missed = [string]$classMethodMissed

            $counterMethod = $oPackageClass.counter | Where-Object { $_.type -eq 'CLASS' }
            $counterMethod.covered = [string]$classClassCovered
            $counterMethod.missed = [string]$classClassMissed

            # Update Sourcefile stats
            $counterInstruction = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
            $counterInstruction.covered = [string]$classInstructionCovered
            $counterInstruction.missed = [string]$classInstructionMissed

            $counterLine = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'LINE' }
            $counterLine.covered = [string]$classLineCovered
            $counterLine.missed = [string]$classLineMissed

            $counterMethod = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'METHOD' }
            $counterMethod.covered = [string]$classMethodCovered
            $counterMethod.missed = [string]$classMethodMissed

            $counterMethod = $oPackageSourcefile.counter | Where-Object { $_.type -eq 'CLASS' }
            $counterMethod.covered = [string]$classClassCovered
            $counterMethod.missed = [string]$classClassMissed

            Write-Verbose "      Class Instruction Covered  : $classInstructionCovered"
            Write-Verbose "      Class Instruction Missed   : $classInstructionMissed"
            Write-Verbose "      Class Line Covered         : $classLineCovered"
            Write-Verbose "      Class Line Missed          : $classLineMissed"
            Write-Verbose "      Class Method Covered       : $classMethodCovered"
            Write-Verbose "      Class Method Missed        : $classMethodMissed"
        }

        $totalInstructionCovered += $packageInstructionCovered
        $totalInstructionMissed += $packageInstructionMissed
        $totalLineCovered += $packageLineCovered
        $totalLineMissed += $packageLineMissed
        $totalMethodCovered += $packageMethodCovered
        $totalMethodMissed += $packageMethodMissed
        $totalClassCovered += $packageClassCovered
        $totalClassMissed += $packageClassMissed

        # Update Package stats
        $counterInstruction = $oPackage.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
        $counterInstruction.covered = [string]$packageInstructionCovered
        $counterInstruction.missed = [string]$packageInstructionMissed

        $counterLine = $oPackage.counter | Where-Object { $_.type -eq 'LINE' }
        $counterLine.covered = [string]$packageLineCovered
        $counterLine.missed = [string]$packageLineMissed

        $counterMethod = $oPackage.counter | Where-Object { $_.type -eq 'METHOD' }
        $counterMethod.covered = [string]$packageMethodCovered
        $counterMethod.missed = [string]$packageMethodMissed

        $counterClass = $oPackage.counter | Where-Object { $_.type -eq 'CLASS' }
        $counterClass.covered = [string]$packageClassCovered
        $counterClass.missed = [string]$packageClassMissed

        Write-Verbose "  Package Instruction Covered: $packageInstructionCovered"
        Write-Verbose "  Package Instruction Missed : $packageInstructionMissed"
        Write-Verbose "  Package Line Covered       : $packageLineCovered"
        Write-Verbose "  Package Line Missed        : $packageLineMissed"
        Write-Verbose "  Package Method Covered     : $packageMethodCovered"
        Write-Verbose "  Package Method Missed      : $packageMethodMissed"
        Write-Verbose "  Package Class Covered      : $packageClassCovered"
        Write-Verbose "  Package Class Missed       : $packageClassMissed"
    }

    #Update Total stats
    $counterInstruction = $Document.report.counter | Where-Object { $_.type -eq 'INSTRUCTION' }
    $counterInstruction.covered = [string]$totalInstructionCovered
    $counterInstruction.missed = [string]$totalInstructionMissed

    $counterLine = $Document.report.counter | Where-Object { $_.type -eq 'LINE' }
    $counterLine.covered = [string]$totalLineCovered
    $counterLine.missed = [string]$totalLineMissed

    $counterMethod = $Document.report.counter | Where-Object { $_.type -eq 'METHOD' }
    $counterMethod.covered = [string]$totalMethodCovered
    $counterMethod.missed = [string]$totalMethodMissed

    $counterClass = $Document.report.counter | Where-Object { $_.type -eq 'CLASS' }
    $counterClass.covered = [string]$totalClassCovered
    $counterClass.missed = [string]$totalClassMissed

    Write-Verbose "----------------------------------------"
    Write-Verbose " Totals"
    Write-Verbose "----------------------------------------"
    Write-Verbose "  Total Instruction Covered : $totalInstructionCovered"
    Write-Verbose "  Total Instruction Missed  : $totalInstructionMissed"
    Write-Verbose "  Total Line Covered        : $totalLineCovered"
    Write-Verbose "  Total Line Missed         : $totalLineMissed"
    Write-Verbose "  Total Method Covered      : $totalMethodCovered"
    Write-Verbose "  Total Method Missed       : $totalMethodMissed"
    Write-Verbose "  Total Class Covered       : $totalClassCovered"
    Write-Verbose "  Total Class Missed        : $totalClassMissed"
    Write-Verbose "----------------------------------------"

    Write-Verbose "Completed merging files and updating statistics!"

    return $Document
}
#EndRegion './Public/Update-JaCoCoStatistic.ps1' 306
#Region './suffix.ps1' 0
# Inspired from https://github.com/nightroman/Invoke-Build/blob/64f3434e1daa806814852049771f4b7d3ec4d3a3/Tasks/Import/README.md#example-2-import-from-a-module-with-tasks
Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'tasks\*') -Include '*.build.*' |
    ForEach-Object -Process {
        $ModuleName = ([System.IO.FileInfo] $MyInvocation.MyCommand.Name).BaseName
        $taskFileAliasName = "$($_.BaseName).$ModuleName.ib.tasks"

        Set-Alias -Name $taskFileAliasName -Value $_.FullName

        Export-ModuleMember -Alias $taskFileAliasName
    }
#EndRegion './suffix.ps1' 11
