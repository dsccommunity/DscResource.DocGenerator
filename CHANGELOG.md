# Changelog for DscResource.DocGenerator

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- `azure-pipelines.yml`
  - Fix linting errors.
  - Move from ubuntu-20.04 to ubuntu-latest.
  - Remove ModuleBuilder patch.
  - Remove install DSC step on Linux.

## [0.13.0] - 2025-02-28

### Removed

- Removed `build.psd1` as it is no longer required to build the project.
- Removed ClassAst functions
  - `Get-ClassResourceProperty`
  - `Get-ClassAst`
  - `Get-ClassResourceAst`

### Added

- Added a devcontainer for development.
- Added private function `ConvertTo-WikiSidebarLinkName` that converts a
  name to a format suitable for use as a Wiki sidebar link.
- New tasks:
  - `Prepare_Markdown_FileNames_For_GitHub_Publish` - This task will prepare
    the markdown file names for publishing to the GitHub Wiki by replacing
    hyphens with spaces and converting Unicode hyphens to standard hyphens.
    It can be controlled by parameter `ReplaceHyphen` in the task, which
    defaults to `$true`.
  - `Clean_WikiContent_For_GitHub_Publish` - This task will remove the top
    level header from any markdown file where the top level header equals the
    filename. The task will convert standard hyphens to spaces and Unicode
    hyphens to standard hyphens before comparison. The task can be controlled
    by parameter `RemoveTopLevelHeader` in the task, which defaults to `$true`.
- Added Helper functions as part of [#163] (https://github.com/dsccommunity/DscResource.DocGenerator/pull/163).
  - `Get-ClassPropertyCustomAttribute`
  - `Get-DscResourceAttributeProperty`
  - `Get-DscPropertyType`
  - `Test-ClassPropertyDscAttributeArgument`

### Changed

- `New-GitHubWikiSidebar`
  - Replaces ASCII hyphens for the Wiki sidebar.
  - Replaces Unicode hyphens with standard hyphens for the Wiki sidebar.
- Task `Generate_Wiki_Content`
  - Now calls `Prepare_Markdown_FileNames_For_GitHub_Publish` after the
    markdown files and external help file for command help has been generated.
  - Now calls `Clean_WikiContent_For_GitHub_Publish` as the last step to
    remove the top level header from any markdown file where the top level
    header equals the filename.
- Task `Generate_Markdown_For_Public_Commands`
  - Verbose output of the markdown files that was created.
- Task `Generate_Markdown_For_DSC_Resources`
  - Outputs a warning message if the old configuration key is used in the
    build configuration but keeps using the old configuration key.
- `New-DscClassResourcePage`
  - Remove using Ast to generate documentation. Fixes [#116](https://github.com/dsccommunity/DscResource.DocGenerator/issues/116).
  - Order properties correctly fixes [#126](https://github.com/dsccommunity/DscResource.DocGenerator/issues/126).

### Fixed

- Fix Dockerfile to include GitVersion alias for PowerShell Extension profile script.
- Fix `.vscode/settings.json` file to exclude unrecognized words.
- Fix pipeline issues on Windows PowerShell due to the issue https://github.com/PoshCode/ModuleBuilder/pull/136.


## [0.12.5] - 2024-08-14

- `Get-ClassResourceProperty`
  - Check for a prefixed and non-prefixed class names [issue #132](https://github.com/dsccommunity/DscResource.DocGenerator/issues/132).
- `azure-pipelines`
  - Pin gitversion to V5.
- Update README with the tasks that were not documented.
- `Generate_Wiki_Content`
  - Change the order of the tasks to avoid getting and exception when
    `source/WikiSource` contain additional markdown files that are copied
    to `output/WikiContent`.

## [0.12.4] - 2024-06-03

### Fixed

- `Generate_Markdown_For_Public_Commands.build`
  - Now the task will skip if PlatyPS is not available.
`Generate_External_Help_File_For_Public_Commands`
  - Now the task will skip if PlatyPS is not available.

## [0.12.3] - 2024-06-01

### Fixed

- `Generate_Markdown_For_Public_Commands.build`
  - Now the task will not try to generate markdown if the module does not
    have any publicly exported commands ([issue #135](https://github.com/dsccommunity/DscResource.DocGenerator/issues/147)).
  - Now has error handling if the script that is called using the call
    operator `&` fails.
`Generate_External_Help_File_For_Public_Commands`
  - Now the task will not fail if there are no extern help file generated,
    which is the case for modules that does not have any publicly exported
    commands ([issue #135](https://github.com/dsccommunity/DscResource.DocGenerator/issues/147)).
  - Now has error handling if the script that is called using the call
    operator `&` fails.

## [0.12.2] - 2024-05-31

### Added

- Task `Package_Wiki_Content` - This task will compress generated documentation
  into a .zip archive.

### Changed

- Skipped failing tests on Linux due to libmi.
- Task `Generate_Wiki_Content` converted to a metatask. Existing
  functionality split into smaller tasks. Fixes ([Issue #135](https://github.com/dsccommunity/DscResource.DocGenerator/issues/135))

## [0.12.1] - 2024-01-21

### Fixed

- `Remove-EscapedMarkdownCode`
  - Add additional escape sequences to remove ([issue #140](https://github.com/dsccommunity/DscResource.DocGenerator/issues/140)).

## [0.12.0] - 2024-01-21

### Removed

- Removed the public command `Split-ModuleVersion` since it is now available
  from the module Sampler.

### Added

- Task `Generate_Markdown_For_Public_Commands` - This task will generate
  markdown documentation for the public commands in the built module.
- Task `Generate_External_Help_File_For_Public_Commands` - This task will
  generate the modules help files to support `Get-Help` for public commands.
  This task is dependent on the task `Generate_Markdown_For_Public_Commands`
  to have been run prior.
- Task `Clean_Markdown_Of_Public_Commands` which will edit the the command
  markdown documentation. For example it will remove the `ProgressAction`
  parameter that PlatyPS remove wrongly add (due to a bug).
- Task `Clean_Markdown_Metadata` which will remove the markdown metadata
  block from the markdown documentation. The metadata block was used for
  other tasks to know what type of content the markdown file contained.
- Task `Generate_Wiki_Sidebar` - This task will generate the GitHub Wiki
  Repository sidebar based on the files present in the built documentation
  folder (defaults to `./output/WikiOutput`).
- Public command `Remove-MarkdownMetadataBlock` that removes metadata from a
  Markdown file.
- Public command `New-GitHubWikiSidebar` generate the GitHub Wiki
  Repository sidebar based on the files present in the built documentation
  folder (defaults to `./output/WikiOutput`).
- Private function `Remove-ParameterFromMarkdown` that removes a parameter
  from a commands markdown documentation.
- Private function `Remove-EscapedMarkdownCode` that removes a escape sequences
  from the markdown documentation (that PlatyPS is making).
- Public command `Edit-CommandDocumentation` that will modify the a generated
  command markdown documentation.
- Public command `Add-NewLine` that can add line endings at the end of a file.

### Changed

- DscResource.DocGenerator
  - Updated pipeline files to support resolving dependencies using ModuleFast
    or PSResourceGet.
  - The built module is now removed from the session when initiating a new
    build. The build pipeline is dogfooding functionality and leaving a
    previous version imported in the session do not use new code.
- Task `Generate_Wiki_Content`
  - Support passing metadata trough the build configuration file (`build.yaml`).
- `New-DscResourceWikiPage`
  - A new parameter `Metadata` that takes a hashtable of metadata. See
    comment-based help for the format of the hashtable.
- `New-DscClassResourceWikiPage`
  - A new parameter `Metadata` that takes a hashtable of metadata. See
    comment-based help for the format of the hashtable.
- `New-DscCompositeResourceWikiPage`
  - A new parameter `Metadata` that takes a hashtable of metadata. See
    comment-based help for the format of the hashtable.
- `New-DscMofResourceWikiPage`
  - A new parameter `Metadata` that takes a hashtable of metadata. See
    comment-based help for the format of the hashtable.

### Fixed

- `Get-CommentBasedHelp` was fixed so it correctly filters out the comment-based
  help from a script file.
- `Remove-MarkdownMetadataBlock` was fixed to only remove the metadata block
  at the top of the file.

## [0.11.2] - 2023-01-03

- `Get-ClassResourceProperty`
  - Regression tests for PR #123.
  - Now longer throws an exception if a parent class that isn't part of the
    module is being used. If a class's source file is not found the class
    is skipped (fixes [issue #127](https://github.com/dsccommunity/DscResource.DocGenerator/issues/127)).

## [0.11.1] - 2022-08-09

### Fixed

- `Get-ClassResourceProperty`
  - Now does a more limited wildcard search for the class script file ([issue #122](https://github.com/dsccommunity/DscResource.DocGenerator/issues/122)).
  - Regression tests.

## [0.11.0] - 2022-05-10

### Changed

- Updated pipelines files to the latest in Sampler.
- Fix missing verbose message in function `Invoke-Git`.
- Fix variable reference for localized strings so they passed HQRM tests.
- Fix statement so function passed HQRM tests.
- Tasks now uses `Set-SamplerTaskVariable` from the module Sampler to set
  the common build task variables.
- Updated task parameters `ProjectName` and `SourcePath` to reflect Sampler

### Fixed

- Common task variables have not been set, fixed that.
- `Get-CompositeSchemaObject` threw an error when a composite did not have
  comment based help, now returns `$null`.

## [0.10.3] - 2022-01-26

### Fixed

- When `_Sidebar.md` or `Footer.md` files already exist in the wiki repo,
  the code did not override these files. Updated the code to generate these
  files when they do not exist in the 'WikiSource' folder
  (fixes [issue #108](https://github.com/dsccommunity/DscResource.DocGenerator/issues/108)).
- When subfolders exist (only for images, not markdown) the Generate_Wiki_Content
  did not copy these files. Updated the code to copy the files recursively
  (fixes [issue #109](https://github.com/dsccommunity/DscResource.DocGenerator/issues/109)).

### Changed

- Moved to the build images `windows-latest` (fixes [issue #112](https://github.com/dsccommunity/DscResource.DocGenerator/issues/112)).

## [0.10.2] - 2022-01-25

### Fixed

- When there is an existing `_Sidebar.md` in the folder 'WikiSource' that is
  copied to the folder 'WikiContent', it will no longer be overwritten
  during publish ([issue #105](https://github.com/dsccommunity/DscResource.DocGenerator/issues/105)).
- Fixed failing unit tests for the task `Publish_GitHub_Wiki_Content`.
- Rearranged and rephrased some text in the README.md to increase
  clarity. Previously some documentation applied to a task, but should have
  applied to the command that the task called.

## [0.10.1] - 2021-10-19

### Changed

- Uses latest version of DscResource.Common (fixes [SqlServerDsc issue #85](https://github.com/dsccommunity/SqlServerDsc/issues/1729)).
- Switched to a new Linux build worker for the pipeline.
- Switched to omi-1.6.8-1.ssl_110.ulinux.x64.deb for tests on new Linux
  image.

### Fixed

- Correctly uses the correct default branch for Codecov.
- `New-DscMofResourceWikiPage`
  - Removed unused mandatory parameter ([issue #85](https://github.com/dsccommunity/DscResource.DocGenerator/issues/85)).

## [0.10.0] - 2021-08-05

### Added

- Added private functions:
  - `Out-GitResult` - Displays `Invoke-Git` returned hashtable
    via Write-Verbose and Write-Debug localized messages.
    Fixes [Issue 90](https://github.com/dsccommunity/DscResource.DocGenerator/issues/90)
  - `Hide-GitToken` - Used to redact the token from the specified
    git command so that the command can be safely outputted in logs.

### Changed

- `Publish-WikiContent`
  - Restored to original structure.
- `Invoke-Git`
  - Added `-PassThru` switch to return result hashtable and not throw
    regardless of ExitCode value when used.
  - Throws when ExitCode -ne 0 and `-PassThru` switch not used.
  - Calls `Out-GitResult` when using `-Debug` or `-Verbose`.

## [0.9.1] - 2021-07-14

### Added

- Added private functions:
  - `Get-CompositeResourceSchemaPropertyContent` - Returns markdown for
    composite resource properties returned by `Get-CompositeSchemaObject`.
  - `New-DscCompositeResourceWikiPage` - Returns the markdown content for a
    wiki page for a DSC composite resource.

### Changed

- `New-DscResourceWikiPage`
  - Added support for creating wiki pages for composite resources.

## [0.9.0] - 2021-07-08

### Added

- Added private functions:
  - `Get-ClassAst` - Returns the AST for a single or all classes.
  - `Get-ClassResourceAst` - Returns the AST for a single or all DSC class
    resources.
  - `Get-ClassResourceProperty` - Returns DSC class resource properties
    from the provided class or classes.
  - `Format-Text` - Format a string according to predefined options.
  - `Get-TemporaryPath` - returns the appropriate temp path for the OS.
  - `Get-ConfigurationAst` - Returns the AST for a single or all configurations.
  - `Get-CompositeSchemaObject` - Returns an object containing the parameters
    and other properties related to a composite resource. The object that is
    returned is different format to a MOF or class-based object and the property
    names are aligned to a configuration parameter block rather than MOF.
  - `Get-CompositeResourceParameterState` - Determines the parameter state of a
    composite resource parameter. This is a meta attribute that will either be
    `Required` or `Write`.
  - `Get-CompositeResourceParameterValidateSet` - Returns the array of values
    contained in the ValidateSet parameter attributes if it exists.
- Added QA test to do some quality checks on the module code and change log.

### Changed

- `New-DscResourceWikiPage`
  - If a class-based resource has a parent class that contains DSC resource
    properties they will now also be returned as part of the DSC resource
    parameters ([issue #62](https://github.com/dsccommunity/DscResource.DocGenerator/issues/62)).
  - Refactored to split into two private functions `New-DscMofResourceWikiPage` and
    `New-DscClassResourceWikiPage`.
- `Get-MofSchemaObject`
  - Refactored to reduce code duplication when adding functions for supporting
    composite resources.
- `Get-ClassResourceCommentBasedHelp`
  - Renamed this function to `Get-CommentBasedHelp` so that it made sense to
    use with composite DSC resources.
  - Enabled the function to extract the comment block if it is not at the top
    of the script file to support composite resources.
- Updated code to pass newly added quality checks.
- `Invoke-Git`
  - Converted to public function.
  - Updated to use `System.Diagnostics.Process` for improved error handling.
  - Returns object, allowing caller to process result.
  - `git` commands no longer use `--quiet` to populate returned object.
  - No longer write a new line to the end of string for the returned properties
    `StandardOutput` and `StandardError`.

### Fixed

- `Publish_GitHub_Wiki_Content`
  - Output message if `$GitHubToken` not specified which skips this task.
    Fixes [Issue 75](https://github.com/dsccommunity/DscResource.DocGenerator/issues/75)
  - Change working folder for the call to `git` with the argument `remote`.
  - Added optional debug configuration option in `build.yml`.
- `Invoke-Git`
  - Set `$TimeOut` to Milliseconds
    Fixes [Issue 84](https://github.com/dsccommunity/DscResource.DocGenerator/issues/84)
  - Calls `git` so it works on both Windows and Linux.
  - Output properties in return value if called with the `Debug` optional
    common parameter.
- `Publish-WikiContent`
  - Remove a unnecessary `Set-Location` so it is possible to remove the
    temporary folder.
  - Fixed code style in tests.
  - Moved verbose statement so it is only outputted in the right context.
  - Fixed bug that prevented the repo to be cloned.

## [0.8.3] - 2021-04-10

### Added

- DscResource.DocGenerator
  - Adding uploading coverage to Codecov.io.

### Fixed

- DscResource.DocGenerator
  - Fixed formatting in the code through out.
  - Minor change in code comment.

## [0.8.2] - 2021-03-19

### Changed

- Fixed the Tasks to support BuiltModuleDirectory and use new Sampler functions.

## [0.8.1] - 2021-03-11

### Changed

- Updated tasks to use the Sampler functions `Get-SamplerProjectName` and `Get-SamplerSourcePath`.
- Made Sampler a required Modules.
- Updated the `build.yaml` & `RequiredModules.psd1` to use `Sampler.GitHubTasks`
  for automation.

## [0.8.0] - 2021-02-08

### Added

- Added a new private function `Get-ClassResourceCommentBasedHelp` to get
  comment-based help from a PowerShell script file.
- Added a new private function `Get-ClassResourcePropertyState` to get
  named attribute argument (from the attribute `[DscProperty()]`) for a
  class-based resource parameter and return the corresponding name used by
  MOF-based resources.
- Added a new private function `Get-ResourceExampleAsMarkdown` that helps
  to return examples as markdown, and to reduce code duplication.
- Added a test helper module `DscResource.DocGenerator.TestHelper.psm1`
  that contain helper functions for tests.
  - Added helper function `Out-Diff` that outputs two text strings in hex
    side-by-side (thanks to [@johanringman](https://github.com/johanringman)
    for help with this one).

### Changed

- `Split-ModuleVersion`
  - This cmdlet is now exported as a public function because it is required
    by the build task `Generate_Wiki_Content`.
- `Generate_Wiki_Content`
  - The Build task `Generate_Wiki_Content` was changed to call the cmdlet
    `New-DscResourceWikiPage` with the correct parameters to support generating
    documentation for class-based resource ([issue #52](https://github.com/dsccommunity/DscResource.DocGenerator/issues/52)).
- `New-DscResourceWikiPage`
  - Now supports generating wiki documentation for class-based resources
    ([issue #52](https://github.com/dsccommunity/DscResource.DocGenerator/issues/52)).
  - **BREAKING CHANGE:** To support class-based resource the parameters were
    renamed to better recognize what path goes where.
  - Each values that are in a `ValueMap` of a MOF schema parameter, or in
    a `ValidateSet()` of a class-based resource parameter, will be outputted
    as markdown inline code.

### Fixed

- `Get-ResourceExampleAsText`
  - Comment-based help was updated to reflect the correct parameters.
- `New-DscResourcePowerShellHelp`
  - Fixed unit tests to support new private function `Get-ClassResourceCommentBasedHelp`
    and use the test helper module `DscResource.DocGenerator.TestHelper.psm1`.
  - It no longer uses `Recurse` when looking for the module's PowerShell
    script files. It could potentially lead to that it found resources that
    are part of common modules in the `Modules` folder.
  - Made use of private functions to reduce duplicate code.
- `Get-DscResourceSchemaPropertyContent`
  - Fixed the private function so that the description property no longer
    output an extra whitespace in some circumstances.

## [0.7.4] - 2021-02-02

### Fixed

- Conceptual help for MOF-based resource works again (broken in v0.7.3)
  ([issue #55](https://github.com/dsccommunity/DscResource.DocGenerator/issues/55)).

## [0.7.3] - 2021-02-02

### Added

- Support conceptual help for class-based resources ([issue #51](https://github.com/dsccommunity/DscResource.DocGenerator/issues/51)).

### Changed

- Renamed default branch to `main` ([issue #49](https://github.com/dsccommunity/DscResource.DocGenerator/issues/49)).

## [0.7.2] - 2021-01-17

### Fixed

- New-WikiFooter
  - Fixed `Encoding`, parameter value passed to `Out-File` to use `ascii` rather
    than `[System.Text.Encoding]::ASCII` ([issue #45](https://github.com/dsccommunity/DscResource.DocGenerator/issues/45)).
- New-WikiSidebar
  - Fixed `Encoding`, parameter value passed to `Out-File` to use `ascii` rather
    than `[System.Text.Encoding]::ASCII` ([issue #45](https://github.com/dsccommunity/DscResource.DocGenerator/issues/45)).
- Set-WikiModuleVersion
  - Fixed `Encoding`, parameter value passed to `Out-File` to use `ascii` rather
    than `[System.Text.Encoding]::ASCII` ([issue #45](https://github.com/dsccommunity/DscResource.DocGenerator/issues/45)).
- Fix the tests for the tasks that recently started failing. The tests
  tried to dot-source the task scripts but that is not possible because
  they need to be run within the scope of `Invoke-Build`. Instead a new
  test was added to make sure the task alias is pointing to an existing
  task script.

## [0.7.1] - 2020-08-05

### Fixed

- New-DscResourcePowerShellHelp
  - Fixed so the cmdlet is case-insensitive when it looks for the README.md
    file in a resource source folder ([issue #42](https://github.com/dsccommunity/DscResource.DocGenerator/issues/42)).

## [0.7.0] - 2020-07-08

### Added

- The build task `Generate_Conceptual_Help` can now remove markdown code
  from the schema MOF parameter descriptions if markdown code is used to
  improve the Wiki documentation.

## [0.6.1] - 2020-07-01

### Fixed

- Update README.md with the correct build task name; 'Publish_GitHub_Wiki_Content'.
- Fixed wiki generation to correctly describe embedded instances in
  parameters and made new section for each embedded instances with
  their parameters ([issue #37](https://github.com/dsccommunity/DscResource.DocGenerator/issues/37)).

### Changed

- The regular expression for `minor-version-bump-message` in the file
  `GitVersion.yml` was changed to only raise minor version when the
  commit message contain the word `add`, `adds`, `minor`, `feature`,
  or `features`.

## [0.6.0] - 2020-06-22

### Added

- Added cmdlet `Publish-WikiContent` that publishes the Wiki content
  generated by the cmdlet `New-DscResourceWikiPage`.
- Added build task `Publish_GitHub_Wiki_Content` that can publish content
  to a GitHub Wiki repository. This task runs the cmdlet `Publish-WikiContent`.
- Added a markdown page `Home.md` to the folder `source/WikiSource` that
  will be published to the GitHub Wiki for each PR that is merged. The
  module version number will be updated prior to pushing to the Wiki.
  This is done by the the build task `Publish_GitHub_Wiki_Content`.

### Removed

- The parameter `WikiSourcePath` was removed from the function `Copy-WikiFolder`.
- The parameter `WikiSourcePath` was removed from the function `Publish-WikiContent`.
- The parameter `WikiSourceFolderName` was removed from the build task
  `Publish_GitHub_Wiki_Content`.
- The function `Publish-WikiContent` will no longer call the function
  `Set-WikiModuleVersion` (it is now done by the task `Generate_Wiki_Content`).

### Changed

- Update the documentation style in the README.md.
- The repository is using the latest version of the module ModuleBuilder.
- The repository was pinned to use version 4.10.1 of the module Pester
  since this repository does not support Pester 5 tests yet.
- Updated `build.ps1` to be able to dogfood build tasks.
- Moved the Wiki source logic from `Publish-WikiContent` to the build task
  `Generate_Wiki_Content` to align with the other tasks that creates a
  build artifact that should be deployed. `Publish-WikiContent` no longer
  changes the build artifact during publishing. The build task
  `Generate_Wiki_Content` now first generates documentation for any existing
  DSC resources. Secondly if the Wiki source folder (defaults to `WikiSource`)
  exists in the source folder then the content of that folder will be copied
  to the Wiki output folder (defaults to `output/WikiOutput`). If there is a
  markdown file called `Home.md` then any module version placeholders (`#.#.#`)
  will be replaced by the built module version.
- The `Set-WikiModuleVersion` was made a public function to be able to
  use it in the build task `Generate_Wiki_Content`.

### Fixed

- Fixed issue with `New-DscResourceWikiPage` where Test-Path was case sensitive
  on Linux machines and therefore didn't find some Readme.md files.
- Minor style and documentation updates to the build tasks `Generate_Wiki_Content`
  and `Generate_Conceptual_Help`.
- Fixed example in comment-based help form cmdlet `New-DscResourceWikiPage`.
- Fixed a problem in the build task `Publish_GitHub_Wiki_Content` that
  made the Wiki output path to not shown correctly.

## [0.5.1] - 2020-05-01

### Added

- Added helper function `Split-ModuleVersion` that is required by the helper
  function `Get-BuiltModuleVersion`.

### Changed

- Replaced the helper function `Get-ModuleVersion` with the helper function
  `Get-BuiltModuleVersion`.

## [0.5.0] - 2020-03-28

### Fixed

- Fix missing documentation in the README.md for the cmdlet `New-DscResourceWikiPage`
  and the build task `Generate_Wiki_Content` ([issue #20](https://github.com/dsccommunity/DscResource.DocGenerator/issues/20)).
- The function `Get-MofSchemaObject` did not correctly create the temporary
  schema file depending on the formatting of the schema.

## [0.4.0] - 2020-02-25

### Added

- Added build tasks `Generate_Wiki_Content` (that runs the cmdlet
  `New-DscResourceWikiPage`). The build task is primarily meant to be run by
  the project [Sampler's](https://github.com/gaelcolas/Sampler) `build.ps1`.
  To make the task available for `Invoke-Build` in a repository that is based
  on [Sampler](https://github.com/gaelcolas/Sampler) add this module to
  required modules, and then in the `build.yaml` add the following.

  ```yaml
  ModuleBuildTasks:
    DscResource.DocGenerator:
      - 'Task.*'
  ```

### Fixed

- Fixes the build task `Generate_Conceptual_Help` to use the correct
  module version folder name for the built module path ([issue #17](https://github.com/dsccommunity/DscResource.DocGenerator/issues/17)).
- Fixes the build task `Generate_Conceptual_Help` to correctly evaluate
  the module version ([issue #21](https://github.com/dsccommunity/DscResource.DocGenerator/issues/21)).

## [0.3.0] - 2020-02-11

### Added

- Added build tasks `Generate_Conceptual_Help` (that runs the cmdlet
  `New-DscResourcePowerShellHelp`). The build task is primarily meant to
  be run by the project [Sampler's](https://github.com/gaelcolas/Sampler)
  `build.ps1`. To make the task available for `Invoke-Build` in a repository
  that is based on [Sampler](https://github.com/gaelcolas/Sampler) add this
  module to required modules, and then in the `build.yaml` add the following.

  ```yaml
  ModuleBuildTasks:
    DscResource.DocGenerator:
      - 'Task.*'
  ```

### Fixed

- Fix the description in the README.md.

## [0.2.0] - 2020-02-06

### Added

- New-DscResourcePowerShellHelp
  - Add new parameter `DestinationModulePath` to be able to set the path
    to a built module (for example) ([issue #9](https://github.com/dsccommunity/DscResource.DocGenerator/issues/9)).

### Fixes

- New-DscResourcePowerShellHelp
  - Fixed comment-based help for the parameter `OutputPath` ([issue #8](https://github.com/dsccommunity/DscResource.DocGenerator/issues/8)).

## [0.1.1] - 2020-02-02

### Added

- Add cmdlet `New-DscResourcePowerShellHelp` to generate conceptual help
  for DSC resources. *This was moved from repo PowerShell/DscResource.Tests.*

### Fixed

- Fixed unit tests to work cross platform.
- Fix status badges in README.md.
- Fix the description in the README.md.
