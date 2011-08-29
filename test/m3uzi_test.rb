require 'rubygems'
require 'm3uzi'
require 'test/unit'
require 'shoulda'

class M3UziTest < Test::Unit::TestCase

  should "instantiate an M3Uzi object" do
    m3u = M3Uzi.new
    assert_equal M3Uzi, m3u.class
  end

  should "read in an index file" do
    m3u = M3Uzi.read_file("#{Rails.root}/test/fixtures/index.m3u8")
    assert_equal M3Uzi, m3u.class
  end

end
