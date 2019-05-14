require 'rubygems'
require_relative "../emar-tempo"
require "test/unit"

class TestEmarPrinter < Test::Unit::TestCase
  def setup
    @printer = EmarTempoPrinter.new 'test',9600
  end

  def test_crc
    a=[0x31,0x24,0x6c,0x42,0x8f,0x4b,0x20,0x64,0x92,0x75,0xa7,
       0x79,0x63,0x61,0xd,0x31,0x2e,0x30,0x30,0xd,0x41,0x2f,0x31,
       0x30,0x30,0x2e,0x30,0x30,0x2f,0x31,0x30,0x30,0x2e,0x30,0x30, 0x2f].map{|c| c.chr}.join()
    assert_equal(14, EmarTempoPrinter.CRCsum(a) )

    a=[0x31,0x24,0x6c,0x42,0x86,0x6b,0x20,0x64,0x6c,0x75,0x7a,
       0x79,0x63,0x61,0xd,0x31,0xd,0x41,0x2f,
       0x31,0x30,0x30,0x2e,0x30,0x30,0x2f,
       0x31,0x30,0x30,0x2e,0x30,0x30,0x2f].map{|c| c.chr}.join()
    assert_equal(0x2a, EmarTempoPrinter.CRCsum(a) )

    a=@printer.conv_encoding("1$lBąk dluzyca#{0xD.chr}1#{0xD.chr}A/100.00/100.00/")
    puts a.each_char.map{|c| c.ord.to_s(16)}.join(',')
    assert_equal(0x2a, EmarTempoPrinter.CRCsum(a) )


  end
end

