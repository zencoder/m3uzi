$:<< File.dirname(__FILE__)
require 'm3uzi/tag'
require 'm3uzi/file'
require 'm3uzi/stream'
require 'm3uzi/version'

class M3Uzi

  # Unsupported: PROGRAM-DATE-TIME DISCONTINUITY
  VALID_TAGS = %w{TARGETDURATION MEDIA-SEQUENCE ALLOW-CACHE ENDLIST KEY}

  attr_accessor :files, :streams
  attr_accessor :tags, :comments
  attr_accessor :final_media_file
  attr_accessor :version

  def initialize
    @files = []
    @streams = []
    @tags = []
    @comments = []
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
    check_version_restrictions
    io_stream << "#EXTM3U\n"
    io_stream << "#EXT-X-VERSION:#{@version.to_i}\n" if @version > 1
    comments.each do |comment|
      io_stream << "##{comment}\n"
    end
    tags.each do |tag|
      next if %w{M3U ENDLIST}.include?(tag.name.to_s.upcase)
      if VALID_TAGS.include?(tag.name.to_s.upcase)
        io_stream << "#EXT-X-#{tag.name.to_s.upcase}"
      else
        io_stream << "##{tag.name.to_s.upcase}"
      end
      tag.value && io_stream << ":#{tag.value}"
      io_stream << "\n"
    end
    files.each do |file|
      io_stream << "#EXTINF:#{file.attribute_string}"
      io_stream << "\n#{file.path}\n"
    end
    streams.each do |stream|
      io_stream << "#EXT-X-STREAM-INF:#{stream.attribute_string}"
      io_stream << "\n#{stream.path}\n"
    end
    io_stream << "#EXT-X-ENDLIST\n" if files.length > 0 && final_media_file
  end

  def write(path)
    check_version_restrictions
    f = ::File.open(path, "w")
    write_to_io(f)
    f.close()
  end


  #-------------------------------------
  # Files
  #-------------------------------------

  def add_file(&block)
    new_file = M3Uzi::File.new
    yield(new_file)
    @files << new_file
  end

  def filenames
    files.map { |file| file.path }
  end


  #-------------------------------------
  # Streams
  #-------------------------------------

  def add_stream(&block)
    new_stream = M3Uzi::Stream.new
    yield(new_stream)
    @streams << new_stream
  end

  def stream_names
    streams.map { |stream| stream.path }
  end


  #-------------------------------------
  # Tags
  #-------------------------------------

  def add_tag(&block)
    new_tag = M3Uzi::Tag.new
    yield(new_tag)
    @tags << new_tag
  end

  def [](key)
    tag_name = key.to_s.upcase.gsub("_", "-")
    obj = tags.detect { |tag| tag.name == tag_name }
    obj && obj.value
  end

  def []=(key, value)
    add_tag do |tag|
      tag.name = key
      tag.value = value
    end
  end


  #-------------------------------------
  # Comments
  #-------------------------------------

  def add_comment(comment)
    @comments << comment
  end

  def <<(comment)
    add_comment(comment)
  end

  def check_version_restrictions
    @version = 1

    # Version 2 Features
    if @tags.detect { |tag| tag.name == 'KEY' && tag.value.to_s =~ /,IV=/ }
      @version = 2 if @version < 2
    end

    # Version 3 Features
    if @files.detect { |file| file.duration.kind_of?(Float) }
      @version = 3 if @version < 3
    end

    # Version 4 Features
    if @files.detect { |file| file.byterange }
      @version = 4 if @version < 4
    end
    if @tags.detect { |tag| ['MEDIA','I-FRAMES-ONLY'].include?(tag.name) }
      @version = 4 if @version < 4
    end

    # NOTES
    #   EXT-X-I-FRAME-STREAM-INF is supposed to be ignored by older clients.
    #   AUDIO/VIDEO attributes of X-STREAM-INF are used in conjunction with MEDIA, so it should trigger v4.

    @version
  end

protected

  def self.type(line)
    case line
    when /^\s*$/
      :whitespace
    when /^#(?!EXT)/
      :comment
    when /^#EXTINF/
      :info
    when /^#EXT(-X)?-STREAM-INF/
      :stream
    when /^#EXT(-X)?-ENDLIST/
      :final
    when /^#EXT(?!INF)/
      :tag
    else
      :file
    end
  end

  def self.parse_general_tag(line)
    line.match(/^#EXT(?:-X-)?(?!STREAM-INF)([^:\n]+)(:([^\n]+))?$/).values_at(1, 3)
  end

  def self.parse_file_tag(line)
    line.match(/^#EXTINF:[ \t]*(\d+),?[ \t]*(.*)$/).values_at(1, 2)
  end

  def self.parse_stream_tag(line)
    match = line.match(/^#EXT-X-STREAM-INF:(.*)$/)[1]
    match.scan(/([A-Z-]+)\s*=\s*("[^"]*"|[^,]*)/) # return attributes as array of arrays
  end

end
