class M3Uzi
  class Tag < Item

    attr_reader :name
    attr_accessor :value

    VALID_TAGS = %w{TARGETDURATION MEDIA-SEQUENCE ALLOW-CACHE}

    def name=(n)
      @name = n.to_s.upcase.gsub("_", "-")
    end

    def format
      string = '#'
      string << "EXT-X-" if VALID_TAGS.include?(name)
      string << name
      string << ":#{value}" if value
      string
    end

  end

end
