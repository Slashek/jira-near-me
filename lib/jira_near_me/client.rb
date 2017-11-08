# frozen_string_literal: true
require 'jira-ruby'
require 'chronic'

module JiraNearMe
  class Client
    attr_reader :client

    SETTINGS = {
      username: 'jira-api',
      password: ENV['JIRA_PASSWORD'],
      context_path: '',
      site: 'https://near-me.atlassian.net',
      rest_base_path: '/rest/api/2',
      auth_type: :basic,
      read_timeout: 120
    }.freeze

    def initialize
      @client = JIRA::Client.new(SETTINGS)
    end
  end
end
