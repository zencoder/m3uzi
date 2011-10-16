class M3Uzi
  class File < Item

    attr_accessor :path, :duration, :description, :byterange, :encryption_key, :encryption_iv

    def attribute_string
      if duration.kind_of?(Float)
        "#{sprintf('%0.3f',duration)},#{description}"
      else
        "#{duration},#{description}"
      end
    end

    def format
      # Need to add key info if appropriate?
      "#EXTINF:#{attribute_string}\n#{path}"
    end

  end
end
