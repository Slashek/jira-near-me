# frozen_string_literal: true

require 'jira-ruby'

module JiraNearMe
  # Releaser is a entry class for the script that manage entire release process.

  class Releaser
    extend Forwardable

    JIRA_FORMAT = /^\A[a-zA-Z]{2,4}[\s-]\d{1,5}/
    TAG_OPTIONS = %w[skip_tag_create tag_type description].freeze

    attr_reader :description, :tag_options,
                :skip_confirmation, :options

    def_delegators :git_tag_helper, :create_tag, :current_tag, :previous_tag,
                   :current_tag_full_name, :tag_description
    def_delegators :messanger, :print_release_info

    def initialize(options = {})
      @options = options
    end

    def release
      create_tag(options) unless options.key?(:skip_tag_create)
      print_release_info(projects, jira_commits, options)
      release_version
    end

    private

    def release_version
      messanger.log(:assign_fix_version, current_tag: current_tag)

      projects.each do |project|
        project.assign_and_release_version(git_tag_helper)
      end

      messanger.print_release_notes(release_notes)
    end

    def release_notes
      projects.map do |project|
        project.release_notes(current_tag_full_name)
      end.compact.join("\n")
    end

    def commits
      @commits ||= git_commit_helper.commits_between_revisions(
        previous_tag, current_tag
      )
    end

    def last_project_tag
      return if JiraNearMe.marketplace_release?
      nm_project.last_version_for_region(region, current_tag).base_tag
    end

    def nm_project
      Project.new(client, client.Project.find('NM'))
    end

    def find_projects
      projects = []
      grouped_project_issuee_keys.each do |project_key, issues_keys|
        if (jira_project = find_project(project_key))
          projects << Project.new(client, jira_project, issues_keys)
        end
      end
      projects
    end

    def find_project(project_key)
      client.Project.find(project_key.upcase)
    rescue JIRA::HTTPError
      puts "Could not find project with key #{project_key}"
      nil
    end

    def all_projects
      projects = []
      client.Project.all.each do |project|
        projects << Project.new(client, project)
      end
      projects
    end

    def projects
      @projects ||= find_projects
    end

    def git_commit_helper
      @git_commit_helper ||= Git::CommitHelper.new
    end

    def git_tag_helper
      @git_tag_helper ||= Git::TagHelper.new(
        region: region, previous_tag: last_project_tag
      )
    end

    def jira_commits
      @jira_commits ||= commits.select { |commit| commit =~ JIRA_FORMAT }
    end

    def issues_keys
      @issues_keys ||= jira_commits.map do |jira_commit|
        jira_commit.scan(JIRA_FORMAT).first.tr(' ', '-')
      end.uniq
    end

    def grouped_project_issuee_keys
      @grouped_project_issuee_keys ||= issues_keys.group_by do |issue_key|
        issue_key.split('-')[0].upcase
      end
    end

    def client
      @client ||= Client.new.client
    end

    def messanger
      @messanger = Messanger.new
    end

    def region
      return if JiraNearMe.marketplace_release?
      @region ||= RegionOptionParser.new(options).region
    end

  end
end
