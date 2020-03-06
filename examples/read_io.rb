require 'rubygems'
require './emar-tempo'
require 'pp'

printer = EmarTempoPrinter.new '/dev/ttyUSB0', 9600

printer.open


# printer.start_debug :comm
ret =printer.read_io_settings
pp ret

#

