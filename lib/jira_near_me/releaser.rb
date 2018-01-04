require 'jira-ruby'
require 'chronic'

module JiraNearMe
  class Releaser
    extend Forwardable

    JIRA_FORMAT = /^\A[a-zA-Z]{2,4}[\s-]\d{1,5}/
    TAG_OPTIONS = %w[skip_tag_create tag_type description].freeze

    attr_reader :description, :region, :git_tag_helper, :tag_options,
                :skip_confirmation

    def_delegator :@git_tag_helper, :current_tag, :previous_tag, :current_tag_full_name

    def initialize(options)
      unless marketplace_release?
        @region = options[:region] || messanger.ask_for_region
        messanger.verify_region(@region)
      end

      @tag_options = options.select { |key, _| TAG_OPTIONS.include?(key) }
      @skip_confirmation = options.key?('skip_confirmation')
    end

    def release
      git_tag_helper.create_tag(tag_options)
      messanger.print_release_info(projects)
      assign_fix_version
      release_version
    end

    private

    def assign_fix_version
      messanger.log(:assign_fix_version, { current_tag: current_tag })
      projects.each do |project|
        project.assign_version(current_tag)
      end
    end

    def release_version
      projects.each { |project| project.release_version!(current_tag_full_name) }
      messanger.print_release_notes(release_notes)
    end

    def release_notes
      projects.map do |project|
        project.release_notes(current_tag_full_name)
      end.compact.join("\n")
    end

    def commits
      @commits ||= git_commit_helper.commits_between_revisions(last_tag, current_tag)
    end

    def last_tag
      if marketplace_release?
        previous_tag
      else
        nm_project.last_version_for_region(region, current_tag).base_tag
      end
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
    rescue
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
      @git_tag_helper ||= Git::TagHelper.new(marketplace_release: marketplace_release?)
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

    def issues_count
      @count || issues.count
    end

    def marketplace_release?
      @marketplace_release ||= JiraNearMe.used_for_marketplace?
    end

    def client
      @client ||= Client.new.client
    end

    def messanger
      @messanger = Messanger.new
    end
  end
end
