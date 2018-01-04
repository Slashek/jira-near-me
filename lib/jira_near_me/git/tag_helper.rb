module JiraNearMe
  module Git
    class TagHelper
      attr_reader :marketplace_release

      def initialize(marketplace_release: )
        @marketplace_release = marketplace_release
      end

      def create_tag!(options={})
        @skip_tag_create = options['skip_tag_create']
        @skip_confirmation = options['skip_confirmation']

        return if @skip_tag_create || @skip_confirmation
        return unless ask_for_tag_creation

        tag_type ||= ask_for_tag_type
        description ||= ask_for_description

        next_tag = current_tag.next_tag(
          major: tag_type.to_sym == :major,
          description: description,
        )

        next_tag.save
      end

      def ask_for_tag_type
        print_log 'Is this a major release?: [y|n] \n'

        if STDIN.gets.strip == 'y'
          print_log "Proceeding with major release"
          :major
        else
          print_log "Proceeding with hotfix release"
          :minor
        end
      end

      def ask_for_description
        print_log 'Please describe this tag: \n'
        print_log "Proceeding with tag description: \"#{description = STDIN.gets.strip}\""
        description
      end

      def ask_for_tag_creation
        binding.pry

        print_log 'Would you like to create new tag? [y|n] \n'
        STDIN.gets.strip == 'y'
      end

      def scope_description
        if current_tag.major_version != previous_tag.major_version
          "Regular Release"
        else
          "Hotfix"
        end
      end

      def current_tag
        Git::Tag.new(`git describe`.split('-')[0])
      end

      def previous_tag
        current_tag.previous_tag
      end

      def current_tag_full_name
        if marketplace_release
          "#{current_tag}.builder"
        else
          "#{current_tag}.#{region}"
        end
      end

      def tag_description
        "#{marketplace_release ? "Frontend" : "Backend"} #{scope_description}"
      end

      def print_log(message)
        puts(message)
      end
    end
  end
end
