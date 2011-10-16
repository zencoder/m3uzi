$:<< File.dirname(__FILE__)
require 'm3uzi/tag'
require 'm3uzi/file'
require 'm3uzi/stream'
require 'm3uzi/comment'
require 'm3uzi/version'

class M3Uzi

  # Tags not supported for writing: PROGRAM-DATE-TIME DISCONTINUITY ENDLIST

  # Header tags are only supported once per file.  Specifying it multiple times
  # will override previous values.
  HEADER_TAGS = %w{TARGETDURATION MEDIA-SEQUENCE ALLOW-CACHE}

  attr_accessor :header_tags, :playlist_items
  attr_accessor :final_media_file
  attr_accessor :version

  def initialize
    @header_tags = {}
    @playlist_items = []
    @final_media_file = true
    @version = 1
  end


  #-------------------------------------
  # Read/Write M3U8 Files
  #-------------------------------------

  ##
  ## For now, reading m3u8 files is not keeping up to date with writing, so we're
  ## disabling it in this version.  (Possibly to be re-introduced in the future.)
  ##
  # def self.read(path)
  #   m3u = self.new
  #   lines = ::File.readlines(path)
  #   lines.each_with_index do |line, i|
  #     case type(line)
  #     when :tag
  #       name, value = parse_general_tag(line)
  #       m3u.add_tag do |tag|
  #         tag.name = name
  #         tag.value = value
  #       end
  #     when :info
  #       duration, description = parse_file_tag(line)
  #       m3u.add_file do |file|
  #         file.path = lines[i+1].strip
  #         file.duration = duration
  #         file.description = description
  #       end
  #       m3u.final_media_file = false
  #     when :stream
  #       attributes = parse_stream_tag(line)
  #       m3u.add_stream do |stream|
  #         stream.path = lines[i+1].strip
  #         attributes.each_pair do |k,v|
  #           k = k.to_s.downcase.sub('-','_')
  #           next unless [:bandwidth, :program_id, :codecs, :resolution].include?(k)
  #           v = $1 if v.to_s =~ /^"(.*)"$/
  #           stream.send("#{k}=", v)
  #         end
  #       end
  #     when :final
  #       m3u.final_media_file = true
  #     else
  #       next
  #     end
  #   end
  #   m3u
  # end

  def write_to_io(io_stream)
    prev_encryption_key = nil
    prev_encryption_iv = nil
    
    check_version_restrictions
    io_stream << "#EXTM3U\n"
    io_stream << "#EXT-X-VERSION:#{@version.to_i}\n" if @version > 1
    
    @header_tags.each do |item|
      io_stream << (item.format + "\n") if item.valid?
    end
    @playlist_items.each do |item|
      io_stream << (item.format + "\n") if item.valid?
    end

    io_stream << "#EXT-X-ENDLIST\n" if items(File).length > 0 && @final_media_file
  end

  def write(path)
    ::File.open(path, "w") { |f| write_to_io(f) }
  end

  def items(kind)
    @playlist_items.select { |item| item.kind_of?(kind) }
  end

  #-------------------------------------
  # Files
  #-------------------------------------

  def add_file(path = nil, duration = nil)
    new_file = M3Uzi::File.new
    new_file.path = path
    new_file.duration = duration
    yield(new_file) if block_given?
    @playlist_items << new_file
  end

  def filenames
    items(File).map { |file| file.path }
  end


  #-------------------------------------
  # Streams
  #-------------------------------------

  def add_stream(path = nil, bandwidth = nil)
    new_stream = M3Uzi::Stream.new
    new_stream.path = path
    new_stream.bandwidth = bandwidth
    yield(new_stream) if block_given?
    @playlist_items << new_stream
  end

  def stream_names
    items(Stream).map { |stream| stream.path }
  end


  #-------------------------------------
  # Tags
  #-------------------------------------

  def add_tag(name = nil, value = nil)
    new_tag = M3Uzi::Tag.new
    new_tag.name = name
    new_tag.value = value
    yield(new_tag) if block_given?
    if HEADER_TAGS.include?(new_tag.name.to_s.upcase)
      @header_tags[new_tag.name.to_s.upcase] = new_tag
    else
      @playlist_items << new_tag
    end
  end

  # def [](key)
  #   tag_name = key.to_s.upcase.gsub("_", "-")
  #   obj = tags.detect { |tag| tag.name == tag_name }
  #   obj && obj.value
  # end
  # 
  # def []=(key, value)
  #   add_tag do |tag|
  #     tag.name = key
  #     tag.value = value
  #   end
  # end


  #-------------------------------------
  # Comments
  #-------------------------------------

  def add_comment(comment = nil)
    new_comment = M3Uzi::Comment.new
    new_commant.text = comment
    yield(new_commant) if block_given?
    @playlist_items << new_comment
  end

  # def <<(comment)
  #   add_comment(comment)
  # end

  def check_version_restrictions
    @version = 1

    #
    # Version 2 Features
    #

    # Check for custom IV
    current_iv = 0
    items(File).each do |item|
      if item.encryption_iv && item.encryption_iv.to_s.downcas != format_iv(current_iv)
        @version = 2 if @version < 2
      end
      current_iv += 1
    end

    # Version 3 Features
    if items(File).detect { |item| item.duration.kind_of?(Float) }
      @version = 3 if @version < 3
    end

    # Version 4 Features
    if items(File).detect { |item| item.byterange }
      @version = 4 if @version < 4
    end
    if items(Tag).detect { |item| ['MEDIA','I-FRAMES-ONLY'].include?(item.name) }
      @version = 4 if @version < 4
    end

    # NOTES
    #   EXT-X-I-FRAME-STREAM-INF is supposed to be ignored by older clients.
    #   AUDIO/VIDEO attributes of X-STREAM-INF are used in conjunction with MEDIA, so it should trigger v4.

    @version
  end

protected

  # def self.type(line)
  #   case line
  #   when /^\s*$/
  #     :whitespace
  #   when /^#(?!EXT)/
  #     :comment
  #   when /^#EXTINF/
  #     :info
  #   when /^#EXT(-X)?-STREAM-INF/
  #     :stream
  #   when /^#EXT(-X)?-ENDLIST/
  #     :final
  #   when /^#EXT(?!INF)/
  #     :tag
  #   else
  #     :file
  #   end
  # end
  # 
  # def self.parse_general_tag(line)
  #   line.match(/^#EXT(?:-X-)?(?!STREAM-INF)([^:\n]+)(:([^\n]+))?$/).values_at(1, 3)
  # end
  # 
  # def self.parse_file_tag(line)
  #   line.match(/^#EXTINF:[ \t]*(\d+),?[ \t]*(.*)$/).values_at(1, 2)
  # end
  # 
  # def self.parse_stream_tag(line)
  #   match = line.match(/^#EXT-X-STREAM-INF:(.*)$/)[1]
  #   match.scan(/([A-Z-]+)\s*=\s*("[^"]*"|[^,]*)/) # return attributes as array of arrays
  # end

  def format_iv(num)
    num.to_s(16).rjust(32,'0')
  end
end
