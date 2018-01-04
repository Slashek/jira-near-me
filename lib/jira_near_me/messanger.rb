module JiraNearMe
  class Messanger
    REGIONS = %w[california sydney oregon].freeze

    attr_reader :options

    def verify_region(region)
      if REGIONS.include?(region)
        print_log "Proceeding with #{region} region"
      else
        print_log 'You need to pass region argument'
        print_log "allowed regions are: #{REGIONS.join(', ')}"
        ask_for_region
      end
    end

    def ask_for_region
      messanger.log(:incorrect_region)

      Releaser::REGIONS.each_with_index do |region, index|
        print_log "#{index}. #{region.capitalize} \n"
      end

      REGIONS[STDIN.gets.strip.to_i]
    end

    def print_release_info(projects)
      log(:print_commit_info,
        commits_log: commits.map { |commit| commit }.join("\n") )
      print_pre_release_message(projects)
      print_user_confirmation unless skip_confirmation
    end

    def print_user_confirmation
      print_log 'Do you want to proceed? [y]'
      user_input = STDIN.gets.strip
      if user_input.strip != 'y'
        print_log 'ABORT'
        exit
      end
      print_log 'Ok, time to update JIRA'
    end

    def print_release_notes(release_notes)
      log(:version_released)
      slack(:slack_release_info, { release_notes: release_notes })
    end

    def card_printer
      @card_printer ||= CardPrinter.new
    end

    def print_pre_release_message(projects)
      @total_issues_count = 0
      projects.each do |project|
        print_log "\n#{project.issues_count} Issues for project #{project.name}\n"
        @total_issues_count += project.issues_count
        project.issues.each do |issue|
          begin
            card_printer.print(issue.to_hash)
          rescue => error
            print_log "Error for card: #{issue.key}. #{error} - can't check if
                      fixVersion already assigned"
          end
        end
      end
      print_log "\nTotal number of jira issues to process:
                #{@total_issues_count}"
      print_log "\nFix version #{@version} will be assigned to all projects and
                issues.\n"

    end

    def log(message_name, options)
      @options = options
      puts(message[message_name])
    end

    def slack(message_name)
      slack_notifier.ping(message(message_name), icon_emoji: ':see_no_evil:')
    end

    def message(message_name)
      messages[message_name]
    end

    def messages
      if JiraNearMe.used_for_marketplace?
        marketplace_release_messages
      else
        platform_release_messages
      end
    end

    def marketplace_release_messages
      {
        slack_release_info: "Frontend production release started for
                            #{JiraNearMe.marketplace_name}.\n#{options[:release_notes]}\n"
      }.merge(common_messages)
    end

    def platform_release_messages
      {
        slack_release_info: "Backend production release started for #{region}.
                            You can check release notes for each project: \n
                            #{options[:release_notes]} \nDetails in #eng-deploys"
      }.merge(common_messages)
    end

    def common_messages
      {
        incorrect_region: 'Region argument is incorrect, please choose one of the available options: \n',
        version_released: 'Versions released',
        print_commit_info: "All commits: \n #{options[:commits_log]}",
        assign_fix_version: "Updating all issues with fix version #{options[:current_tag]}"
      }
    end

    def print_log(message_log)
      puts(message_log)
    end

    def slack_notifier
      @slack_notifier ||= JiraNearMe::SlackNotifier.new
    end
  end
end
