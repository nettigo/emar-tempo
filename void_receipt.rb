require 'rubygems'
require './emar-tempo'


printer = EmarTempoPrinter.new '/dev/ttyUSB0', 9600

printer.open

printer.start_debug :parsing
puts printer.void_receipt

puts printer.read_error

