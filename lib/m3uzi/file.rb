class M3Uzi
  class File

    attr_accessor :path, :duration, :description, :byterange

    def attribute_string
      if duration.kind_of?(Float)
        "#{sprintf('%0.3f',duration)},#{description}"
      else
        "#{duration},#{description}"
      end
    end

  end
end
