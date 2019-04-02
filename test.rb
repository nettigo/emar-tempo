require 'rubygems'
require './emar-tempo'


printer = EmarTempoPrinter.new '/dev/ttyUSB0', 9600

printer.open

# puts printer.status
# printer.qr_code('https://nettigo.pl/')
# printer.start_debug :parsing
# printer.read_error
# printer.get_version
# puts printer.status

printer.start_debug :comm
printer.start_debug :encoding
# printer.set_encoding
# printer.login_cashier("Kierownik Pociągu", 1)
puts printer.start_receipt #['#12345', 'linia 11111', 'linia 2222']
# puts printer.read_error
# # sleep(1)
am=0

# (1..3).each do |i|
#   printer.add_receipt_entry 1, "Pozycja #{1}", 0.5, 'A', 300, 150
#   am += 150
  printer.add_receipt_entry 1, "Ωµ²Bąk dluzyca", 1, 'A', 100, 100
  am += 100
  # printer.add_receipt_entry 3, "GżeGrzÓŁka", 20, 'A', 10, 200
  # am += 200
  # puts printer.read_error
  # sleep(1)
# end
# puts printer.close_receipt 'KIERPOCIAGU', am, am,['^0 ^232424', 'Zapraszamy ponownie http://nettigo.pl']

puts printer.extended_close_receipt '',
                                    am,
                                    {
                                        lines: ['^0 ^W-30999', 'Zapraszamy ponownie http://nettigo.pl'],
                                        cash: 10,
                                        payments: [
                                            {type: 6, name: 'NAJLEPSZE', amount: 30},
                                            {type: 3, name: 'ŁÓDŹ', amount: 30},
                                            {type: 4, name: 'PRZELEW', amount: 30}
                                        ]


                                    }

# puts printer.extended_close_receipt '',
#                                     am,
#                                     {
#                                        lines: ['^0 ^232424', 'Zapraszamy ponownie http://nettigo.pl'],
#                                         cash: 40,
#                                         payments: [
#                                             {type: 4, name: 'Majsterkowo', amount: 10},
#                                             {type: 6, name: 'Kunto', amount: 10}
#                                         ]
#
#
#                                     }
# puts printer.void_receipt
puts printer.read_error
# printer.logout_cashier("KIER POC", 1)

