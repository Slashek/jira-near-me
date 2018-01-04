# frozen_string_literal: true

require 'test_helper'
require 'pry'

# Test of jira-near-me CLI
class JiraNearMeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::JiraNearMe::VERSION
  end

  def test_valid_region
    valid_region = JiraNearMe::RegionOptionParser.new(region: 'oregon')
    assert valid_region.valid?
  end

  def test_invalid_region
    STDIN.stub :gets, '0' do
      @region = JiraNearMe::RegionOptionParser.new(region: 'ioregon')
    end

    assert @region.valid?
    assert_equal JiraNearMe::RegionOptionParser::REGIONS[0], @region.region
  end

  def test_create_tag
    JiraNearMe.stubs(:marketplace_release?).returns(true)
    @releaser = JiraNearMe::Releaser.new

    options = { tag_type: :major, description: 'Some test tag' }
    JiraNearMe::Git::Tag.any_instance.stubs(:save).returns('OK')

    assert_equal 'OK', @releaser.create_tag(options)
  end

  def test_print_release_info
    fake_marketplace_release
    fake_slack
    options = { skip_tag_create: 'true', skip_confirmation: 'true'}
    @releaser = JiraNearMe::Releaser.new(options)
    @releaser.release
  end

  private

  def fake_marketplace_release
    JiraNearMe::Git::CommitHelper.any_instance.stubs(:commits_between_revisions)
                                 .returns(commit_list)
    JiraNearMe.stubs(:marketplace_release?).returns(true)
    # JiraNearMe::Releaser.any_instance.stubs(:projects).returns(projects)
  end

  def fake_slack
    JiraNearMe::SlackNotifier.any_instance.stubs(:slack_notifier)
                             .returns(FakeNotifier.new)
  end

  def commit_list
    ['JTP-1 test commit', 'JTP-2 test commit 2']
  end

  def projects
    [JiraNearMe::Project.new(jira_client, jira_project, [])]
  end

  def jira_client
    @client = JIRA::Client.new({})
  end

  def jira_project
    JIRA::Resource::Project.new jira_client, 'name' => 'Test'
  end

  class FakeNotifier
    def ping(message, options)
      puts message
      puts options
    end
  end
end
