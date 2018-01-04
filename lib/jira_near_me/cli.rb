# frozen_string_literal: true

require 'thor'
require 'jira_near_me'

module JiraNearMe
  # Command Line Interface see Thor gem for more information
  class CLI < Thor
    desc 'release', 'Performs the release on Jira.
      Fix version will be assigned to all projects and tickets.'
    method_option 'region',
                  required: false,
                  type: :string,
                  aliases: :r,
                  desc: 'Region for the release'
    method_option 'skip-tag-create',
                  required: false,
                  type: :string,
                  aliases: :st,
                  desc: 'Region for the release'
    method_option 'skip-confirmation',
                  required: false,
                  type: :string,
                  aliases: :sc,
                  desc: 'Region for the release'

    def release
      releaser.release
    end

    no_commands do
      def releaser
        @jira_releaser ||= JiraNearMe::Releaser.new(options)
      end
    end
  end
end
