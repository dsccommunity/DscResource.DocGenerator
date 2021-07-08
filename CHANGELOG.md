# Change log for DscResource.DocGenerator

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Updated the `build.yaml` & `RequiredModules.psd1` to use `Sampler.GitHubTasks` for automation.

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
