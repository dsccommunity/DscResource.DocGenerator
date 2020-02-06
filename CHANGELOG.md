# Change log for DscResource.DocGenerator

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- New-DscResourcePowerShellHelp
  - Add new parameter `DestinationModulePath` to be able to set the path
    to a built module (for example) ([issue #9](https://github.com/dsccommunity/DscResource.DocGenerator/issues/9)).

### Fixes

- New-DscResourcePowerShellHelp
  - Fixes comment-based help for the parameter `OutputPath` ([issue #8](https://github.com/dsccommunity/DscResource.DocGenerator/issues/8)).

## [0.1.1] - 2020-02-02

### Added

- Add cmdlet `New-DscResourcePowerShellHelp` to generate conceptual help
  for DSC resources. *This was moved from repo PowerShell/DscResource.Tests.*

### Fixed

- Fixed unit tests to work cross platform.
- Fix status badges in README.md.
