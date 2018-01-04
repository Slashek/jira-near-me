module JiraNearMe
  module Git
    class Tag
      def initialize(tag, description=nil)
        @tag = tag
        @description = description
      end

      def region
        @tag.split('.')[3]
      end

      def base_tag
        @tag.split('.')[0..2].join('.')
      end

      def to_s
        @tag.strip
      end

      def major_version
        @tag.split('.')[0..1].join('.')
      end

      def next_tag(major: true, description:)
        return @next_tag if @next_tag.present?

        number_position = major ? 1 : 2
        arr = @tag.split('.')
        arr[number_position] = arr[number_position].to_i + 1
        arr[2] = 0 if number_position == 1

        @next_tag = Tag.new("#{arr.join('.').strip}", description)
      end

      def previous_tag
        Tag.new(`#{previous_tag_command}`)
      end

      def previous_tag_command
        "git for-each-ref --sort=-taggerdate --count=2 --format '%(tag)' refs/tags | tail -1"
      end

      def save
        `git tag -a #{@tag} -m '#{@description}'`
        `git push --tags`
      end
    end
  end
end
