# JiraNearMe

JiraNearMe is a command line interface that ease the pain of jira ticket mnagement
after each release.

## Installation

use the command below to install gem

    $ gem install jira-near-me

## Usage

You can use JiraNearMe for both marketplaces and core app. There are 3 available commands:

- `prepare` - moves all tickets that are about to releae to Ready for release state. This command is reserved for core application.

      $ jira-near-me prepare

- `release` - creates proper fixVersion based on last tag and gien region, then assigns all tickets to that version. Available parameters are:

      $ jira-near-me release

  - `skip_tag_create=true` if you've already created tag manually. By default tag will be generated automatically.
  - `region` when core app is released. Asked when skipped.

- `release_version` - release versions in jira and post release notes to slack.

      $ jira-near-me release_version
