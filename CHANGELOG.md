# Change log for DscResource.DocGenerator

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
