# frozen_string_literal: true

module JiraNearMe
  class Issue
    QA_TEST_STATES = ["send to qa team", 'ready to test', 'ready to test by near me qa']

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

    def move_to_ready_for_test
      puts "Checking issue: #{issue.key}"
      return unless ['ready for qa'].include?(issue.status.name.downcase)
      return unless transition_to_qa_test_state
      puts "\tmoving to #{transition_to_qa_test_state.name}"

      transition = issue.transitions.build
      begin
        transition.save!('transition' => { 'id' => transition_to_qa_test_state.id })
      rescue
        puts "Faied to move #{issue.key}"
      end
    end

    def transition_to_qa_test_state
      @transition_to_qa_test_state ||= available_transitions.select {|t| QA_TEST_STATES.include?(t.name.downcase) }.first
    end

    def available_transitions
      @available_transitions ||= @project_wrapper.client.Transition.all(issue: issue)
    end
  end
end
