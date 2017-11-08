require 'jira-ruby'
require 'chronic'

module JiraNearMe
  class Releaser
    JIRA_FORMAT = /^\A[a-zA-Z]{2,4}[\s-]\d{1,5}/
    REGIONS = %w[california sydney oregon].freeze

    attr_reader :projects, :description, :region

    def initialize(region:)
      @client = Client.new.client
      unless JiraNearMe.used_for_marketplace?
        @region = region || ask_for_region
        verify_region(@region)
      end
    end

    def release!
      create_git_tag
      print_commit_info
      print_pre_release_message
      assign_fix_version
    end

    # Moves all jira cards to 'ready to test'
    def prepare
      projects.each(&:prepare)
    end

    # Triggered by deploy script
    def release_version!
      projects.each { |project| project.release_version!(tag_full_name) }
      print_log 'Versions released'
      slack_notifier.ping(release_message, icon_emoji: ':see_no_evil:')
    end

    def release_message
      if JiraNearMe.used_for_marketplace?
        "Frontend production release started for #{JiraNearMe.marketplace_name}.\n
        #{release_notes} \n"
      else
        "Backend production release started for #{region}. You can check release
        notes for each project: \n#{release_notes} \nDetails in #eng-deploys"
      end
    end

    def create_git_tag
      return if ENV['skip_tag_create'] == 'true'
      git_tag_helper = Git::TagHelper.new
      git_tag_helper.create_tag!(
        tag_type: ENV['tag_type'],
        description: ENV['description'],
      )
    end

    # Triggered by deploy script
    def release_notes
      notes = []
      projects.map { |project| notes << project.release_notes(tag_full_name) }
      notes.compact.join("\n")
    end

    private

    def ask_for_region
      print_log 'Region argument is incorrect, please choose one of the available options: \n'

      REGIONS.each_with_index do |region, index|
        print_log "#{index}. #{region.capitalize} \n"
      end

      REGIONS[STDIN.gets.strip.to_i]
    end

    def commits
      @commits ||= git_commit_helper.commits_between_revisions(previous_tag, current_tag)
    end

    def current_tag
      git_tag_helper.current_tag.to_s
    end

    def tag_full_name
      if JiraNearMe.used_for_marketplace?
        "#{current_tag}.builder"
      else
        "#{current_tag}.#{region}"
      end
    end

    def previous_tag
      if JiraNearMe.used_for_marketplace?
        Git::Tag.new(current_tag).previous_tag
      else
        nm_project.last_version_for_region(region, current_tag).base_tag
      end
    end

    def nm_project
       Project.new(@client, @client.Project.find('NM'))
     end

    def projects
      @projects ||= find_projects
    end

    def git_commit_helper
      @git_commit_helper ||= Git::CommitHelper.new
    end

    def git_tag_helper
      @git_tag_helper ||= Git::TagHelper.new
    end

    def print_commit_info
      print_log "\nAll commits: "
      commits.each {|c| print_log c }
      print_log "\n"
    end

    def jira_commits
      @jira_commits ||= commits.select { |c| c =~ JIRA_FORMAT }
    end

    def issues_keys
      @issues_keys ||= jira_commits.map { |jira_commit| to_jira_number([jira_commit]).first.tr(' ', '-') }.uniq
    end

    def projects_keys_with_grouped_issues_keys
      @projects_keys_with_grouped_issues_keys ||= issues_keys.group_by {|i| i.split('-')[0].upcase }
    end

    def to_jira_number(array)
      array.map { |a| a.scan(JIRA_FORMAT).first }
    end

    def find_projects
      projects = []
      projects_keys_with_grouped_issues_keys.each do |project_key, issues_keys|
        projects << Project.new(@client, find_project(project_key), issues_keys)
      end
      projects
    end

    def find_project(project_key)
      @client.Project.find(project_key.upcase)
    rescue
      puts "Could not find project with key #{project_key}"
      nil
    end

    def all_projects
      projects = []
      @client.Project.all.each do |project|
        projects << Project.new(@client, project)
      end
      projects
    end

    def print_pre_release_message
      @printer = CardPrinter.new

      @total_issues_count = 0
      projects.each do |project|
        print_log "\n#{project.issues_count} Issues for project #{project.name}\n"
        @total_issues_count += project.issues_count
        project.issues.each do |issue|
          begin
            @printer.print(issue.to_hash)
          rescue => e
            print_log "Error for card: #{issue.key}. #{e} - can't check if fixVersion already assigned"
          end
        end
      end
      print_log "\nTotal number of jira issues to process: #{@total_issues_count}"
      print_log "\nFix version #{@version} will be assigned to all projects and issues.\n"
      print_log 'Do you want to proceed? [y]'

      user_input = STDIN.gets.strip
      if user_input.strip != 'y'
        print_log 'ABORT'
        exit
      end
      print_log 'Ok, time to update JIRA'
    end

    def issues_count
      @count || issues.count
    end

    def assign_fix_version
      print_log "Updating all issues with fix version #{current_tag}"
      projects.each do |project|
        print_log "Processing project: #{project.name}"
        project.assign_version(tag_full_name, tag_description)
      end
    end

    def tag_description
      "#{release_type} #{git_tag_helper.scope_description}"
    end

    def release_type
      JiraNearMe.used_for_marketplace? ? "Frontend" : "Backend"
    end

    def print_log(message)
      puts(message)
    end

    def verify_region(region)
      unless REGIONS.include?(region)
        print_log "You need to pass region argument, allowed regions are: #{REGIONS.join(', ')}"
        ask_for_region
      else
        print_log "Proceeding with #{region} region"
      end
    end

    def slack_notifier
      @slack_notifier ||= JiraNearMe::SlackNotifier.new
    end
  end
end
