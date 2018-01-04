# frozen_string_literal: true

module JiraNearMe
  class Issue

    attr_reader :issue
    delegate :key, to: :issue

    def initialize(issue, project_wrapper)
      @issue = issue
      @project_wrapper = project_wrapper
    end

    def to_hash
      return nil unless issue
      {
        name: issue.key + ' ' + issue.summary,
        fixVersions: assigned_versions.join(', '),
        status: issue.status.name,
        assignee: issue.assignee.try(:displayName),
        sprint: issue.customfield_10007.try(:map) { |s| s.split('name=')[1].split(':')[0] }.try(:join, ', '),
        epic: epic_for_issue(issue)
      }
    end

    def epic_for_issue(issue)
      @project_wrapper.epic_hash[issue.customfield_10008]
    end

    def assign_version(version)
      unless released_for_region?(Git::Tag.new(version).region)
        unless issue.save(fields: { fixVersions: assigned_versions.map {|v| {name: v} } + [{ name: version }] })
          puts issue.errors
        else
          puts "Assigned version #{version} to #{issue.key} \n"
        end
      end
    end

    def released_for_region?(region)
      return false if region.blank?
      assigned_versions.any? do |version|
        if version =~ Regexp.new("#{region}$")
          puts "#{issue.key} already released in #{version}. Skipping."
          true
        end
      end
    end

    def assigned_versions
      @assigned_versions ||= issue.fixVersions.map(&:name)
    end

    def available_transitions
      @available_transitions ||= @project_wrapper.client.Transition.all(issue: issue)
    end
  end
end
