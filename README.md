# DscResource.DocGenerator

[![Build Status](https://dev.azure.com/dsccommunity/DscResource.DocGenerator/_apis/build/status/dsccommunity.DscResource.DocGenerator?branchName=main)](https://dev.azure.com/dsccommunity/DscResource.DocGenerator/_build/latest?definitionId=19&branchName=main)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/DscResource.DocGenerator/19/main)
[![codecov](https://codecov.io/gh/dsccommunity/DscResource.DocGenerator/branch/main/graph/badge.svg)](https://codecov.io/gh/dsccommunity/DscResource.DocGenerator)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/DscResource.DocGenerator/19/main)](https://dsccommunity.visualstudio.com/DscResource.DocGenerator/_test/analytics?definitionId=19&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/DscResource.DocGenerator?label=DscResource.DocGenerator%20Preview)](https://www.powershellgallery.com/packages/DscResource.DocGenerator/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/DscResource.DocGenerator?label=DscResource.DocGenerator)](https://www.powershellgallery.com/packages/DscResource.DocGenerator/)

Functionality to help generate documentation for modules.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `main` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out the DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).
This repository align to the [DSC Community Style Guidelines](https://dsccommunity.org/styleguidelines).

## Known Issues

### Composite Resources and Linux

The cmdlets and tasks that generate documentation for composite resources require
the `configuration` statement that is provided by DSC. DSC is not installed
on Linux by default, so these cmdlets This cmdlet will fail on Linux if the DSC
resource module contains any composite resources. To enable these cmdlets to work
on Linux, please install [PowerShell DSC for Linux](https://github.com/Microsoft/PowerShell-DSC-for-Linux).

## Cmdlets

Refer to the comment-based help for more information about these helper
functions.

```powershell
Get-Help -Name <CmdletName> -Detailed
```

### `New-DscResourcePowerShellHelp`

Generates conceptual help based on the DSC resources and their examples in
a DSC module. This currently only creates English (culture en-US) conceptual
help. MOF, class-based and composite resources are supported. Class-based resources
must follow the template pattern of the [Sampler](https://github.com/gaelcolas/Sampler)
project. See the project [AzureDevOpDsc](https://github.com/dsccommunity/AzureDevOpsDsc)
for an example of the pattern.

After the conceptual help has been created, the user can import the module
and for example run `Get-Help about_UserAccountControl` to get help about
the DSC resource UserAccountControl.

It is possible to pass a array of regular expressions that should be used
to parse the parameter descriptions in the schema MOF. The regular expression
must be written so that the capture group 0 is the full match and the
capture group 1 is the text that should be kept.

>**NOTE:** This cmdlet does not work on macOS and will throw an error due
>to the problem discussed in issue https://github.com/PowerShell/PowerShell/issues/5970
>and issue https://github.com/PowerShell/MMI/issues/33.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
New-DscResourcePowerShellHelp [-ModulePath] <string> [[-DestinationModulePath] <string>] 
  [[-OutputPath] <string>] [[-MarkdownCodeRegularExpression] <string[]>]
  [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

```powershell
cd c:\source\MyDscModule

New-DscResourcePowerShellHelp -ModulePath '.'
```

### `New-DscResourceWikiPage`

Generate documentation that can be manually uploaded to the GitHub repository
Wiki.

It is possible to use markdown code in the schema MOF parameter descriptions.
If markdown code is used and conceptual help is also to be generated, configure
the task [`Generate_Conceptual_Help`](#generate_conceptual_help) to parse the
markdown code. See the cmdlet `New-DscResourcePowerShellHelp` and the task
[`Generate_Conceptual_Help`](#generate_conceptual_help) for more information.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
New-DscResourceWikiPage [-OutputPath] <string> [-ModulePath] <string> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

```powershell
cd c:\source\MyDscModule

New-DscResourceWikiPage -ModulePath '.' -OutputPath '.\output\WikiContent'
```

### `Publish-WikiContent`

Publishes the Wiki content that was generated by the cmdlet `New-DscResourceWikiPage`.

If there is an existing `_Sidebar.md` present in the `WikiOutput` folder then
it will be published. If there is no existing `_Sidebar.md` in the `WikiOutput`
folder a `_Sidebar.md` file will be dynamically generated based on the files
in the `WikiOutput` folder.

>**NOTE:** There must already be a Wiki created in the GitHub repository
>before using this cmdlet, otherwise it will fail since there is no Wiki
>repository.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Publish-WikiContent [-Path] <string> [-OwnerName] <string> [-RepositoryName] <string>
  [-ModuleName] <string> [-ModuleVersion] <string> [-GitHubAccessToken] <string>
  [-GitUserEmail] <string> [-GitUserName] <string>
  [[-GlobalCoreAutoCrLf] {true | false | input}] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

```powershell
cd c:\source\MyDscModule

Publish-WikiContent `
    -Path '.\output\WikiContent' `
    -OwnerName 'dsccommunity' `
    -RepositoryName 'SqlServerDsc' `
    -ModuleName 'SqlServerDsc' `
    -ModuleVersion '14.0.0' `
    -GitHubAccessToken 'token' `
    -GitUserEmail 'email@contoso.com' `
    -GitUserName 'dsc' `
```

Adds the content pages in '.\output\WikiContent' to the Wiki for the
specified GitHub repository.

```powershell
cd c:\source\MyDscModule

Publish-WikiContent `
    -Path '.\output\WikiContent' `
    -OwnerName 'dsccommunity' `
    -RepositoryName 'SqlServerDsc' `
    -ModuleName 'SqlServerDsc' `
    -ModuleVersion '14.0.0' `
    -GitHubAccessToken 'token' `
    -GitUserEmail 'email@contoso.com' `
    -GitUserName 'dsc'
```

Adds the content pages in '.\output\WikiContent' to the Wiki for the
specified GitHub repository.

```powershell
cd c:\source\MyDscModule

Publish-WikiContent `
    -Path '.\output\WikiContent' `
    -OwnerName 'dsccommunity' `
    -RepositoryName 'SqlServerDsc' `
    -ModuleName 'SqlServerDsc' `
    -ModuleVersion '14.0.0' `
    -GitHubAccessToken 'token' `
    -GitUserEmail 'email@contoso.com' `
    -GitUserName 'dsc' `
    -GlobalCoreAutoCrLf 'true'
```

Adds the content pages in '.\output\WikiContent' to the Wiki for the
specified GitHub repository. The wiki repository will be cloned after the
git configuration setting `--global core.autocrlf` have been set to `true`
making sure the current wiki files are checkout using CRLF.

### `Set-WikiModuleVersion`

Changes all placeholders (#.#.#) in a markdown file to the specified
module version.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Set-WikiModuleVersion [-Path] <string> [-ModuleVersion] <string> [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

None.

#### Example

```powershell
Set-WikiModuleVersion -Path '.\output\WikiContent\Home.md' -ModuleVersion '14.0.0'
```

Replaces '#.#.#' with the module version '14.0.0' in the markdown file 'Home.md'.

### `Split-ModuleVersion`

This function parses a module version string as returns a hashtable
which each of the module version's parts.

#### Syntax

<!-- markdownlint-disable MD013 - Line length -->
```plaintext
Split-ModuleVersion [[-ModuleVersion] <string>] [<CommonParameters>]
```
<!-- markdownlint-enable MD013 - Line length -->

#### Outputs

System.Management.Automation.PSCustomObject

#### Example

```powershell
Split-ModuleVersion -ModuleVersion '1.15.0-pr0224-0022+Sha.47ae45eb'
```

Splits the module version an returns a PSCustomObject with the parts
of the module version.

```plaintext
Version PreReleaseString ModuleVersion
------- ---------------- -------------
1.15.0  pr0224           1.15.0-pr0224
```

## Tasks

These are `Invoke-Build` tasks. The build tasks are primarily meant to be
run by the project [Sampler's](https://github.com/gaelcolas/Sampler)
`build.ps1` which wraps `Invoke-Build` and has the configuration file
(`build.yaml`) to control its behavior.

To make the tasks available for the cmdlet `Invoke-Build` in a repository
that is based on the [Sampler](https://github.com/gaelcolas/Sampler) project,
add this module to the file `RequiredModules.psd1` and then in the file
`build.yaml` add the following:

```yaml
ModuleBuildTasks:
  DscResource.DocGenerator:
    - 'Task.*'
```

### `Generate_Conceptual_Help`

This build task runs the cmdlet `New-DscResourcePowerShellHelp`.

Below is an example how the build task can be used when a repository is
based on the [Sampler](https://github.com/gaelcolas/Sampler) project.

```yaml
BuildWorkflow:
  '.':
    - build

  build:
    - Clean
    - Build_Module_ModuleBuilder
    - Build_NestedModules_ModuleBuilder
    - Create_changelog_release_output
    - Generate_Conceptual_Help
```

If the schema mof property descriptions contain markdown code then it is
possible to configure regular expressions to remove the markdown code.
The regular expressions must be written so that capture group 0 returns 
the full match and the capture group 1 returns the text that should be kept. 
For example the regular expression `` \`(.+?)\` `` will find `` `$true` ``
which will be replaced to `$true` since that is what will be returned by
capture group 1.

Below is some example regular expressions for the most common markdown code.

>**NOTE:** Each regular expression must be able to find multiple matches
>on the same row.

```yaml
DscResource.DocGenerator:
  Generate_Conceptual_Help:
    MarkdownCodeRegularExpression:
      - '\`(.+?)\`' # Match inline code-block
      - '\\(\\)' # Match escaped backslash
      - '\[[^\[]+\]\((.+?)\)' # Match markdown URL
      - '_(.+?)_' # Match Italic (underscore)
      - '\*\*(.+?)\*\*' # Match bold
      - '\*(.+?)\*' # Match Italic (asterisk)
```

>**NOTE:** If the task is used in a module that is using the project [Sampler's](https://github.com/gaelcolas/Sampler)
>`build.ps1` then version 0.102.1 of [Sampler](https://github.com/gaelcolas/Sampler)
>is required.

### `Generate_Wiki_Content`

This build task runs the cmdlet `New-DscResourceWikiPage` to build
documentation for DSC resources.

The task will also copy the content of the wiki source folder if it exist
(the parameter `WikiSourceFolderName` defaults to `WikiSource`). The wiki
source folder should be located under the source folder, e.g. `source/WikiSource`.
The wiki source folder is meant to contain additional documentation that
will be added to folder `WikiOutput` during build, and then published to
the wiki during the deploy stage (if either the command `Publish-WikiContent`
or the task `Publish_GitHub_Wiki_Content` is used).

if the `Home.md` is present in the folder specified in `WikiSourceFolderName`
it will be copied to `WikiOutput` and all module version placeholders (`#.#.#`)
of the content the file will be replaced with the built module version.

See the cmdlet `New-DscResourceWikiPage` for more information.

Below is an example how the build task can be used when a repository is
based on the [Sampler](https://github.com/gaelcolas/Sampler) project.

```yaml
BuildWorkflow:
  '.':
    - build

  build:
    - Clean
    - Build_Module_ModuleBuilder
    - Build_NestedModules_ModuleBuilder
    - Create_changelog_release_output
    - Generate_Wiki_Content
```

### `Publish_GitHub_Wiki_Content`

This build task runs the cmdlet `Publish-WikiContent`. The task will only
run if the variable `$GitHubToken` is set either in parent scope, as an
environment variable, or if passed to the build task.

See the cmdlet `Publish-WikiContent` for more information.

Below is an example how the build task can be used when a repository is
based on the [Sampler](https://github.com/gaelcolas/Sampler) project.

>**NOTE:** This task is meant to be run after the task `Generate_Wiki_Content`
>that is normally run in the build phase. But this task can be used to upload
>any content to a Wiki.

```yaml
BuildWorkflow:
  '.':
    - build

  build:
    - Clean
    - Build_Module_ModuleBuilder
    - Build_NestedModules_ModuleBuilder
    - Create_changelog_release_output
    - Generate_Wiki_Content

  publish:
    - Publish_release_to_GitHub
    - publish_module_to_gallery
    - Publish_GitHub_Wiki_Content
```

It is also possible to enable debug output information for the task when
it is run by adding this to the build configuration:

```yaml
DscResource.DocGenerator:
  Publish_GitHub_Wiki_Content:
    Debug: true
```
