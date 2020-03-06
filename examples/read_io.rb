require 'rubygems'
require './emar-tempo'


printer = EmarTempoPrinter.new '/dev/ttyUSB0', 9600

printer.open


printer.start_debug :comm
printer.read_io_settings
puts printer.read_error
# printer.logout_cashier("KIER POC", 1)

