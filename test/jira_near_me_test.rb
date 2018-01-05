# frozen_string_literal: true

require 'test_helper'
require 'pry'

# Test of jira-near-me CLI
class JiraNearMeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::JiraNearMe::VERSION
  end

  # def test_jira_release
  # @jira_releaser ||= JiraNearMe::Releaser.new({})
  # assert true
  # end

  def test_valid_region
    valid_region = JiraNearMe::RegionOptionParser.new(region: 'oregon')
    assert valid_region.valid?
  end

  def test_invalid_region
    STDIN.stub :gets, '0' do
      @region = JiraNearMe::RegionOptionParser.new(region: 'ioregon')
    end

    assert @region.valid?
  end
end
