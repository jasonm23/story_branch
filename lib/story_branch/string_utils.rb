# frozen_string_literal: true

module StoryBranch
  # Utility class for string manipulation
  class StringUtils
    def self.dashed(s)
      s.tr(' _,./:;+&', '-')
    end

    def self.simple_sanitize(s)
      strip_newlines(s.tr('\'"%!@#$(){}[]*\\?', ''))
    end

    def self.normalised_branch_name(s)
      simple_sanitize((dashed s).downcase).squeeze('-')
    end

    def self.strip_newlines(s)
      s.tr "\n", '-'
    end

    def self.undashed(s)
      s.tr('-', ' ').capitalize
    end
  end
end
