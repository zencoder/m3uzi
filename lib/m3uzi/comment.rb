class M3Uzi
  class Comment < Item

    attr_accessor :text

    def format
      "# #{text}"
    end
  end
end
