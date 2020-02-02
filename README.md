# DscResource.DocGenerator

[![Build Status](https://dev.azure.com/dsccommunity/DscResource.DocGenerator/_apis/build/status/dsccommunity.DscResource.DocGenerator?branchName=master)](https://dev.azure.com/dsccommunity/DscResource.DocGenerator/_build/latest?definitionId=19&branchName=master)
![Azure DevOps coverage (branch)](https://img.shields.io/azure-devops/coverage/dsccommunity/DscResource.DocGenerator/19/master)
[![Azure DevOps tests](https://img.shields.io/azure-devops/tests/dsccommunity/DscResource.DocGenerator/19/master)](https://dsccommunity.visualstudio.com/DscResource.DocGenerator/_test/analytics?definitionId=19&contextType=build)
[![PowerShell Gallery (with prereleases)](https://img.shields.io/powershellgallery/vpre/DscResource.DocGenerator?label=DscResource.DocGenerator%20Preview)](https://www.powershellgallery.com/packages/DscResource.DocGenerator/)
[![PowerShell Gallery](https://img.shields.io/powershellgallery/v/DscResource.DocGenerator?label=DscResource.DocGenerator)](https://www.powershellgallery.com/packages/DscResource.DocGenerator/)

Manage change log files in the keepachangelog.com format.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Releases

For each merge to the branch `master` a preview release will be
deployed to [PowerShell Gallery](https://www.powershellgallery.com/).
Periodically a release version tag will be pushed which will deploy a
full release to [PowerShell Gallery](https://www.powershellgallery.com/).

## Contributing

Please check out the DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).
This repository align to the [DSC Community Style Guidelines](https://dsccommunity.org/styleguidelines).

## Cmdlet

Refer to the comment-based help for more information about these helper
functions.

```powershell
Get-Help -Name <CmdletName> -Detailed
```

### `New-DscResourcePowerShellHelp`

Generates conceptual help based on the mof-based DSC resources and their
examples  in a DSC module. This currently only creates english (culture en-US)
conceptual help.

```powershell
cd c:\source\MyDscModule
New-DscResourcePowerShellHelp -ModulePath '.'
```

After the conceptual help has been created, the user can import the module
and for example run `Get-Help about_UserAccountControl` to get help about
the DSC resource UserAccountControl.

>**NOTE:** This cmdlet does not work on macOS and will throw an error due 
>to the problem discussed in issue https://github.com/PowerShell/PowerShell/issues/5970
>and issue https://github.com/PowerShell/MMI/issues/33.
