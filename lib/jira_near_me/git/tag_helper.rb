# frozen_string_literal: true

module JiraNearMe
  module Git
    class TagHelper
      attr_reader :region

      def initialize(region:, previous_tag:)
        @region = region
        @previous_tag = previous_tag
      end

      def create_tag(options = {})
        tag_type = options[:tag_type]
        description = options[:description]

        if (tag_type && description) || ask_for_tag_creation
          tag_type ||= ask_for_tag_type
          description ||= ask_for_description

          next_tag = current_tag.next_tag(
            major: tag_type.to_sym == :major,
            description: description
          )

          next_tag.save
        end
      end

      def ask_for_tag_type
        print_log 'Is this a major release?: [y|n] \n'

        if STDIN.gets.strip == 'y'
          print_log 'Proceeding with major release'
          :major
        else
          print_log 'Proceeding with hotfix release'
          :minor
        end
      end

      def ask_for_description
        print_log 'Please describe this tag: \n'
        print_log "Proceeding with tag description: \"#{description = STDIN.gets.strip}\""
        description
      end

      def ask_for_tag_creation
        print_log 'Would you like to create new tag? [y|n] \n'
        STDIN.gets.strip == 'y'
      end

      def current_tag
        Git::Tag.new(`git describe`.split('-')[0])
      end

      def previous_tag
        @previous_tag ||= current_tag.previous_tag
      end

      def current_tag_full_name
        if JiraNearMe.marketplace_release?
          "#{current_tag}.builder"
        else
          "#{current_tag}.#{region}"
        end
      end

      def tag_description
        "#{JiraNearMe.marketplace_release? ? 'Frontend' : 'Backend'} #{scope_description}"
      end

      def scope_description
        if current_tag.major_version != previous_tag.major_version
          'Regular Release'
        else
          'Hotfix'
        end
      end

      def print_log(message)
        puts(message)
      end
    end
  end
end
