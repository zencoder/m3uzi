class M3Uzi
  class Stream < Item

    attr_accessor :path, :bandwidth, :program_id, :codecs, :resolution

    # Unsupported tags: EXT-X-MEDIA, EXT-X-I-FRAME-STREAM-INF
    # Unsupported attributes of EXT-X-STREAM-INF: AUDIO, VIDEO

    def attribute_string
      s = []
      s << "PROGRAM-ID=#{(program_id || 1).to_i}"
      s << "BANDWIDTH=#{bandwidth.to_i}"
      s << "CODECS=\"#{codecs}\"" if codecs
      s << "RESOLUTION=#{resolution}" if resolution
      s.join(',')
    end

    def format
      "#EXT-X-STREAM-INF:#{attribute_string}\n#{path}"
    end

    def valid?
      !!(path && bandwidth)
    end
  end

end
