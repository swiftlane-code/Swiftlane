# Swiftlane

Swiftlane is a fully open-source alternative to Fastlane, built entirely in Swift.

It provides a more modern and type-safe way of automating the building, testing, and deployment of iOS apps, while still offering the same level of customization and flexibility as Fastlane.

## Requirements

* MacOS 12+

## Motivation

We love Swift and we wanted to make use of it for our CI.

That way we got compile time safe, type safe, written in well-known language code base covered with unit tests.

In the past we used to use fastlane + [danger/swift](https://github.com/danger/swift). Why we moved away from it?

* We are iOS developers and we know Swift well unlike Ruby with all of it's caveats.
* Proper Swift infrastructure (danger scripts were getting huge and inconvenient very fast)
* Type safe code
* Unit tests and debugging? Easy!

# Status

The project is not in the active development state. But all the implemented code has been running on our CI for a long time so we can definately call it stable and working.

Instructions are mostly complete, check the "Getting Started" section.

## Closest Plans

* Enrich README and provide detailed instructions on how to configure Swiftlane for your CI
* GitHub integration
* A lot more features :)

# Features

Keep in mind that at the moment Swiftlane only supports projects of iOS apps.

Detailed information about available commands is provided in the CLI tool itself, see the "Getting Started" section on how to build it.

Some of the features of Swiftlane include:

* Modular architecture that allows for easy customisation, extension, and testability
* Detailed logging with support of loglevels and verbose logfiles to make sure nothing is hidden from your eyes
* Perform various checks
	* run swiftlint
	* check code coverage limits
	* look after TODOs with resolution dates
	* verify characters used in files and folders names
	* restrict changes in specific files of your repo
* Build, test, archive and deploy your apps
	* build without testing
	* run unit and UI tests
	* run tests on multiple simulators in parallel
	* archive an .ipa with fine control which provisioning profiles to use
	* upload your .ipa to AppStoreConnect or Firebase AppDistribution
	* manage DSYMs
* Manage code signing certificates and provisioning profiles
	* Encrypted git repo storage for certs and profiles (compatible with [Fastlane match](https://docs.fastlane.tools/actions/match/))
	* Dramatically eases the process of creating and updating certificates and provisioning profiles
	* Automatically includes all active devices from Apple Developer Portal into your provisioning profile
	* One-tap installation of certs and profiles on developers' machines and CI
* Control version and build number of your app
	* Allows to **correctly** update version or build number of your project with just one command
* Guardian (As of now we only support integration with GitLab)
	* Human readable messages about steps, information and any errors of running CI job as a comment to merge request

## What is implemented under the hood

Swiftlane is built around modular architecture

### Integration with CLIs

We have implemented a few services to use 3rd party CLIs in safe, convenient and predictable way.

* xcodebuild
	* build
	* test
	* archive
	* run tests on multiple simulators in parallel (with fine control)
* xccov
	* obtain code coverage data
* simctl 
	* create, clone, reset, boot, etc. your iOS simulators
* [SwiftLint](https://github.com/realm/SwiftLint)
	* lint your code
* [Sentry](https://github.com/getsentry/sentry)
	* upload your dsyms to Sentry
* [periphery](https://github.com/peripheryapp/periphery)
	* scan for unused code
* [XCLogParser](https://github.com/MobileNativeFoundation/XCLogParser)
	* parse build logs

### Integration with web APIs

* Custom NetworkingClient which wraps URLSession to make building new API Clients fast, easy, and readable (and somewhat declarative)
* API Clients to allow integrations with:
	* AppStoreConnect (based on [Bagbutik](https://github.com/MortenGregersen/Bagbutik))
	* Jira (custom implementation)
	* GitLab (custom implementation)
	* FirebaseAppDistribution (custom implementation)

# Getting Started

This repo contains implementation of all the functionality described in the "Features" section above.

> [!IMPORTANT]  
> Take a look at example runner here https://github.com/swiftlane-code/SwiftlaneCI.

## Installation

Using [Mint](https://github.com/yonaskolb/mint):
```sh
$ mint install swiftlane-code/Swiftlane
```

Using the Swift Package Manager:
```sh
$ git clone https://github.com/swiftlane-code/Swiftlane.git
$ cd Swiftlane
$ swift build -c release
$ cp -f .build/release/SwiftlaneCLI /usr/local/bin/
```

Check out the builtin help. We tried our best to make a good description for all commands and options.

```bash
$ mint run Swiftlane --help
# OR
$ .build/release/SwiftlaneCLI --help
```

## Running unit tests

Before running tests you need to generate mocks.

```bash
$ ./bootstrap
```

[Script](Scripts/bootstrap_project.sh) will clone and build SwiftyMocky and then use it to generate mocks.

# Customisation

We are going to describe this a little later.

# Contributing

Swiftlane is an open-source project, and we welcome contributions from anyone who is interested in improving it. Whether you want to fix a bug, add a new feature, or just help with the documentation, we would love to have your help.

To contribute to Swiftlane, you can fork the repository, make your changes, and submit a pull request. We will review your changes and merge them if they meet our quality standards.

# License

Swiftlane is licensed under the [Apache License 2.0](LICENSE).

# Credits

Swiftlane was originally developed by:
* [Viacheslav Zhivetyev](https://github.com/vmzhivetyev)
* [Anton Medoks](https://github.com/tercteberc)
* [Dmitriy Kulakov](https://github.com/navartis)
