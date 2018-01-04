# frozen_string_literal: true

module JiraNearMe
  class Project
    attr_reader :project, :client
    delegate :key, :name, to: :project

    def initialize(client, project, issue_keys=[])
      @client = client
      @project = project
      @issues = find_project_issues(filter_keys(issue_keys)).map do |issue|
        Issue.new(issue, self) if issue
      end.compact
    end

    def release_notes(fix_version_name)
      return unless (v = version(fix_version_name)).present?

      release_notes_url = "https://near-me.atlassian.net/secure/ReleaseNote.jspa?projectId=#{project.id}&version=#{v.id}"
      "<a href='#{release_notes_url}'>Check #{project.name} #{JiraNearMe.used_for_marketplace? ? 'Frontend ' : ''}Release Notes</a>."
    end

    def assign_version(version, description)
      ensure_version_present!(name: version, description: description)
      i = 0
      issues.each do |issue|
        i += 1
        issue.assign_version(version)
        puts "Version assigned to #{i}/#{issues_count}" if (i % 10).zero? || i == issues_count
      end
    end

    # We dont want to process NM-0000 keys as they do not
    # exist in Jira.
    def filter_keys(issue_keys)
      issue_keys.reject { |k| k =~ /^#{key}-0+$/ }
    end

    def issues
      @issues || []
    end

    def issues_count
      @issues.size
    end

    def find_project_issues(issue_keys)
      @client.Issue.jql("project=#{key} AND id IN (#{issue_keys.join(',')})")
    rescue
      issue_keys.map do |issue_key|
        find_project_issue(issue_key)
      end
    end

    def find_project_issue(issue_key)
      @client.Issue.find(issue_key)
    rescue
      puts "[WARNING] Issue #{issue_key} does not exists in Jira"
    end

    def ensure_version_present!(name:, description:)
      puts "Ensuring version exists: #{name} for project #{project.name}"
      unless version(name).present?
        splitted_version = name.split('.')
        if splitted_version.last == '0' && has_versions?
          previous_version = [splitted_version[0], splitted_version[1].to_i - 1, 0].join('.')
          old_version = version(previous_version)
          if old_version
            user_start_date = old_version.userReleaseDate
          else
            user_start_date = Time.current.strftime('%-d/%b/%y')
          end
        else
          user_start_date = Time.current.strftime('%-d/%b/%y')
        end
        user_released_date = Time.current.strftime('%-d/%b/%y')

        hash = {
          description: description,
          name: name,
          projectId: project.id,
          userStartDate: user_start_date,
          userReleaseDate: user_released_date
        }
        puts "\tDoes not exists for project #{project.name}, creating: #{hash.inspect}"
        current_version = @client.Version.build
        current_version.save(hash)
        @versions << current_version
      end
      current_version
    end

    def epic_hash
      unless @epics
        @epics = {}
        cards = @client.Issue.jql("project = #{project.key} AND type = 'Epic'", max_results: 500)
        cards.each do |card|
          @epics[card.key] ||= card.summary
        end
      end
      @epics
    end

    def has_versions?
      versions.any?
    end

    def version(tag)
      versions.detect { |v| v.name == tag }
    end

    def last_version_for_region(region, current_tag)
      tag_name = versions_before(current_tag).detect { |v| v.name =~ Regexp.new(region || '') }.try(:name)
      tag_name ||= versions_before(current_tag).map(&:name).grep(/^\d+\.\d+\.\d+$/).last
      Git::Tag.new(tag_name)
    end

    def versions_before(current_tag)
      versions.inject([[]]) do |results, version|
        if version.name =~ Regexp.new("#{current_tag}")
           results << []
         else
           results.last << version
         end

         results
      end.first
    end

    def versions
      @versions ||= project.versions || []
    end

    def release_version!(tag)
      if version(tag)
        version(tag).save(released: true)
        puts "Version #{tag} for project #{project.name} released."
      else
        puts "Could not release version #{tag} for project #{project.name} because it doesn't exist."
      end
    end
  end
end
