require 'rubygems'
require 'm3uzzi'
require 'test/unit'
require 'shoulda'

class M3UzziTest < Test::Unit::TestCase

  should "instantiate an M3Uzzi object" do
    m3u = M3Uzzi.new
    assert_equal M3Uzzi, m3u.class
  end

  should "read in an index file" do
    m3u = M3Uzzi.read_file("#{Rails.root}/test/fixtures/index.m3u8")
    assert_equal M3Uzzi, m3u.class
  end

end
