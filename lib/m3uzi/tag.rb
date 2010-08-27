class M3Uzi

  class Tag

    attr_reader :name
    attr_accessor :value

    def name=(n)
      @name = n.to_s.upcase.gsub("_", "-")
    end

  end

end
