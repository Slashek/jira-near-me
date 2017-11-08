require "jira_near_me/version"
require 'jira_near_me/releaser.rb'
require 'jira_near_me/card_printer.rb'
require 'jira_near_me/client.rb'
require 'jira_near_me/project.rb'
require 'jira_near_me/issue.rb'
require 'jira_near_me/slack_notifier.rb'
require 'jira_near_me/git.rb'
require 'jira_near_me/errors/jira_near_me_error'

module JiraNearMe
  MARKETPLACE_BUILDER_FOLDER = 'marketplace_builder'.freeze

  def self.used_for_marketplace?
    File.exists?(builder_folder)
  end

  def self.builder_folder
    "#{Dir.getwd}/#{MARKETPLACE_BUILDER_FOLDER}/"
  end

  def self.marketplace_name
    `git remote -v | tail -1`.match(/\/([A-z-]*)\.git/)[1].gsub('-', ' ').capitalize
  end
end
