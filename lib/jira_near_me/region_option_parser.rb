# frozen_string_literal: true

module JiraNearMe
  # Region parser for options passed in CLI
  class RegionOptionParser
    REGIONS = %w[california sydney oregon].freeze
    attr_reader :region

    def initialize(options)
      @region = options[:region]
      ask_for_region
      messanger.log(:region_set, region: region)
    end

    def ask_for_region
      return if valid?

      info_message
      @region = REGIONS[STDIN.gets.strip.to_i]

      ask_for_region
    end

    def info_message
      messanger.log(:incorrect_region, region: region)

      REGIONS.each_with_index do |region, index|
        messanger.print_log "#{index}. #{region.capitalize} \n"
      end
    end

    def messanger
      @messanger ||= Messanger.new
    end

    def valid?
      REGIONS.include?(@region)
    end
  end
end
