class M3Uzi
  class Stream < Item

    attr_accessor :path, :bandwidth, :program_id, :codecs, :resolution

    def attribute_string
      s = []
      s << "PROGRAM-ID=#{program_id || 1}"
      s << "BANDWIDTH=#{bandwidth}" if bandwidth
      s << "CODECS=\"#{codecs}\"" if codecs
      s << "RESOLUTION=#{resolution}" if resolution
      s.join(',')
    end

    def format
      "#EXT-X-STREAM-INF:#{attribute_string}\n#{path}"
    end
  end

end
