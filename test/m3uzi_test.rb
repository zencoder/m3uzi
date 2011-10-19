$: << File.join(File.dirname(__FILE__),'../lib')
require 'm3uzi'
require 'test/unit'
require 'rubygems'
require 'shoulda'

class M3UziTest < Test::Unit::TestCase

  context "basic checks" do
    should "instantiate an M3Uzi object" do
      m3u = M3Uzi.new
      assert_equal M3Uzi, m3u.class
    end

    # should "read in an index file" do
    #   m3u = M3Uzi.read(File.join(File.dirname(__FILE__), "fixtures/index.m3u8"))
    #   assert_equal M3Uzi, m3u.class
    # end
  end

  context "with protocol versions" do
    should "set version 2 for encryption IV" do
      m3u = M3Uzi.new
      m3u.add_file('1.ts',10) { |f| f.encryption_key_url = "key.dat" }
      assert_equal 1, m3u.check_version_restrictions
      m3u.add_file('1.ts',10) { |f| f.encryption_key_url = "key.dat"; f.encryption_iv = "0x1234567890abcdef1234567890abcdef" }
      assert_equal 2, m3u.check_version_restrictions

      output_stream = StringIO.new
      m3u.write_to_io(output_stream)
      assert output_stream.string =~ /,IV=/
    end

    should "set version 3 for floating point durations" do
      m3u = M3Uzi.new
      m3u.add_file do |f|
        f.path = "stuff.ts"
        f.duration = 10
      end
      assert_equal 1, m3u.check_version_restrictions

      output_stream = StringIO.new
      m3u.write_to_io(output_stream)
      assert output_stream.string =~ /:10,/
      assert output_stream.string !~ /:10\./

      m3u = M3Uzi.new
      m3u.add_file do |f|
        f.path = "stuff.ts"
        f.duration = 10.0
      end
      assert_equal 3, m3u.check_version_restrictions

      output_stream = StringIO.new
      m3u.write_to_io(output_stream)
      assert output_stream.string =~ /:10\.0000,/
      assert output_stream.string !~ /:10,/
    end

    should "set version 4 for advanced features" do
      m3u = M3Uzi.new
      m3u.add_file do |f|
        f.path = "stuff.ts"
        f.duration = 10
      end
      assert_equal 1, m3u.check_version_restrictions

      m3u = M3Uzi.new
      m3u.add_file do |f|
        f.path = "stuff.ts"
        f.duration = 10.0
        f.byterange = "1234@0"
      end
      assert_equal 4, m3u.check_version_restrictions
    end
  end

end
