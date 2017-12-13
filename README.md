# JiraNearMe

JiraNearMe is a command line interface that ease the pain of jira ticket mnagement
after each release.

## Installation

to install the gem type 

    $ gem install jira-near-me-0.1.1.gem

next, add ENV variable (preferably, add it to ~/.bash_profile or something like this) 

    export SLACK_RELEASE_SERVICE=xxx

(you can take proper value from https://nearme.slack.com/services/B2JGMA27M - find Webhook URL and copy everything after https://hooks.slack.com/services/ - first character should be T)

## Usage

If you are using the gem in frontend repo for the first time, you might want to do following: checkout to the first commit, add a first tag and then checkout to master, something like:
    
    git tag -a 0.0.1 -m 'init'
    git push --tags
    git checkout master
    
Then you will be able to use JiraNearMe for both marketplaces and core app. There are 2 available commands:

- `release` - creates proper fixVersion based on last tag and region, then assigns all tickets to that version. DO NOT FORGET TO PUSH TAG AFTER YOU CREATE IT via `gem push --tags`. Available parameters are:

      $ jira-near-me release

  - `skip_tag_create=true` if you've already created tag manually. By default tag will be generated automatically.
  - `region` when core app is released. Asked when skipped.

- `release_version` - release versions in jira and post release notes to slack.

      $ jira-near-me release_version
      

