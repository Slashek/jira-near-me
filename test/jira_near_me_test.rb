require 'test_helper'

class JiraNearMeTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::JiraNearMe::VERSION
  end

  def jira_releaser_test
    jira_releaser = JiraNearMe::Releaser.new
    jira_releaser.release
    assert true
  end

end
