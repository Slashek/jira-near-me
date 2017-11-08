module JiraNearMe
  module Git
    class CommitHelper
      def commits_between_revisions(base_revision, new_revision)
        @commits ||= begin
                       cmd = "git log #{base_revision}..#{new_revision} --pretty=format:\"%s\" --no-merges"
                       puts "Commits between revisions: #{cmd}"
                       `#{cmd}`.split("\n")
                     end
      end
    end
  end
end
