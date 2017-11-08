# frozen_string_literal: true
module JiraNearMe
  class SlackNotifier
    def ping(message, options)
      return error unless slack_api_key

      slack_notifier.ping(message, options)
    end

    private
    def slack_notifier
      @slack_notifier ||= Slack::Notifier.new(slack_url)
    end

    def slack_url
      "https://hooks.slack.com/services/#{slack_api_key}"
    end

    def slack_api_key
      ENV['SLACK_RELEASE_SERVICE']
    end

    def error
      Errors::JiraNearMeError.new("In order to notify via Slack you need to set SLACK_RELEASE_SERVICE global variable")
    end
  end
end
