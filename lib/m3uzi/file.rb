class M3Uzi

  class File

    attr_accessor :path, :duration, :description

    def attribute_string
      s = []
      s << duration
      s << description if description
      s.join(',')
    end
  end

end
