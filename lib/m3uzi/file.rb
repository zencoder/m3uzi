class M3Uzi
  class File

    attr_accessor :path, :duration, :description

    def attribute_string
      "#{duration},#{description}"
    end

  end
end
