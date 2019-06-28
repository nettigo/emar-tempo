require 'rubygems'
require './emar-tempo'
require 'optparse'
@opts = ARGV.getopts('p:')
pp @opts
@prt_port = @opts["p"]
@prt_port ||= "/dev/ttyUSB0"

printer = EmarTempoPrinter.new @prt_port, 9600

printer.open

printer.start_debug :parsing
puts printer.void_receipt

puts printer.read_error

