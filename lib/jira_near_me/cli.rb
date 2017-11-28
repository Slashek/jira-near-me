require 'thor'
require 'pry'
require 'slack-notifier'
require 'jira_near_me'

module JiraNearMe
  class CLI < Thor

    desc 'prepare', 'Prepares jira tickets for the release'
    def prepare
      releaser.prepare
    end

    desc 'release', 'Performs the release on Jira. Fix version will be assigned to all projects and tickets.'
    method_option 'region', required: false, type: :string, aliases: :r, desc: 'Region for the release'
    method_option 'skip-tag-create', required: false, type: :string, aliases: :skip, desc: 'Region for the release'
    def release
      releaser.release!
    end

    desc 'release_version', 'Release Fix Version.'
    method_option 'region', type: :string, aliases: :r, desc: 'Region for the release'
    def release_version
      releaser.release_version!
    end

    no_commands do
      def releaser
        @jira_releaser ||= JiraNearMe::Releaser.new(region: options[:region])
      end
    end
  end
end
