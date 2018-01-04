# frozen_string_literal: true

require 'thor'
require 'jira_near_me'
require 'pry'

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

    def options
      super.each_with_object({}) do |(key, value), memo|
        memo[key.tr('-', '_').to_sym] = value
      end
    end

    no_commands do
      def releaser
        @jira_releaser ||= JiraNearMe::Releaser.new(options)
      end
    end
  end
end
