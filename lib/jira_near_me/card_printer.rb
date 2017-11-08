module JiraNearMe
  class CardPrinter
    def initialize
    end

    def print(issue_hash)
      puts %(
    Number: #{issue_hash[:name]}
    \tfixVersions: #{issue_hash[:fixVersions]}
    \tstatus: #{issue_hash[:status]}
    \tassignee: #{issue_hash[:assignee]}
    \tepic: #{issue_hash[:epic]}
    \tsprint: #{issue_hash[:sprint]}
      )
    end
  end
end
