require 'serialport'
require_relative 'printer-comm'

class EmarTempoPrinter
  attr_accessor :printer
  # attr_accessor :debug
  #
  include EmarTempoComm


  def initialize(port, bd = 9600, db = 8, sb = 1, p = SerialPort::NONE)
    @port = port
    @baud_rate = bd
    @data_bits = db
    @stop_bits = sb
    @parity = p
    @debug = []
  end

  def start_receipt(lines = [])
    cmd = "0#{lines.size}$h#{lines.join(0xD.chr)}"
    send_command(cmd)
    read_and_parse
  end

  #szerokośc w bajtach nie pikselach
  def send_header graph, width, lines, opts = {}
    opts[:align] ||= 0 #0 - center, 1 do prawej, 2 do lewej
    opts[:hdr] ||= 0  #0 hdr, 1 footer
    (1..lines).each {|i|
      cmd="251;#{i};#{i==lines ? '1' : '0'};#{width};0;0$d"
       puts("#{((i-1)*width)} -> #{(i*width-1)}") if should_debug(:graph)
      graph[((i-1)*width)..(i*width-1)].each{|b| cmd += sprintf("%02X",b)}
      puts cmd if should_debug(:graph)
      send_command(cmd)
      read_and_parse
    }
  end

  def add_receipt_entry no, name, amount, ptu, price, total
    amount = amount2str(amount)
    price = amount2str(price)
    total = amount2str(total)
    cmd = "#{no}$l#{conv_encoding(name)}#{0xD.chr}#{amount}#{0xD.chr}#{ptu}/#{price}/#{total}/"
    send_command(cmd)
    read_and_parse
  end

  def set_encoding
    cmd = "0$1" #mazovia
    send_command(cmd)
    read_and_parse
  end

  def conv_encoding(str)
    encoded = str.unpack("U*").map {|b|
      ret = '.'
      if b > 210 #zeby złapać Ó i ó
        ret = MAZOVIA_HASH[b].chr
        print "#{[b].pack("U*")} -> #{MAZOVIA_HASH[b].to_s(16)}," if should_debug(:encoding)
        ret ||= '.'
      else
        ret = b.chr
      end
      ret
    }.join()
    puts if should_debug(:encoding)
    encoded
  end


  def close_receipt name, paid, total, lines = []
    paid = amount2str(paid)
    total = amount2str(total)
    cmd = "1;0;#{lines.size.to_s};0;0;0$e"
    cmd += "#{conv_encoding(name)}#{0xD.chr}#{join_cr(lines)}"
    cmd += "#{paid.to_s}/#{total.to_s}/0/"
    send_command(cmd)
    read_and_parse
  end

  def login_cashier cashier, no
    cmd = "0#p#{conv_encoding(cashier)}#{CR.chr}#{no}#{CR.chr}"
    send_command(cmd)
    read_and_parse
  end

  def logout_cashier cashier, no
    cmd = "0#q#{cashier}#{CR.chr}#{no}#{CR.chr}"
    send_command(cmd)
    read_and_parse
  end

  def extended_close_receipt name, total, opts = {}
    opts[:lines] ||= []
    discount_type = 0

    total = amount2str(total)

    cash = opts[:cash].to_f != 0
    paid_in_cash = amount2str(opts[:cash].to_f)

    payments = opts[:payments]
    payments ||= []

    cmd = "#{opts[:lines].size.to_s};0;0;0;"
    cmd += "#{discount_type};0;0;0;#{payments.size};0;#{cash ? 1 : 0};#{payments.collect {|p| p[:type]}.join(';')}"
    cmd += "$y#{CR.chr}"
    cmd += "#{conv_encoding(name)}#{CR.chr}#{CR.chr}#{join_cr(opts[:lines])}"
    cmd += "#{join_cr(payments.collect {|p| conv_encoding(p[:name])})}"
    cmd += "#{total}/#{paid_in_cash}/0.00/#{paid_in_cash}/#{payments.collect {|p| amount2str(p[:amount].to_f)}.join('/')}/0.00/"
    send_command(cmd)
    read_and_parse
  end

  def extended_close_receipt_x name, total, opts = {}
    opts[:lines] ||= []
    discount_type = 0

    total = amount2str(total)

    cash = opts[:cash].to_f != 0
    paid_in_cash = amount2str(opts[:cash].to_f)

    coupon = !opts[:coupon_name].to_s.empty?
    coupon_value = amount2str(opts[:coupon_value].to_f)

    cmd = "#{opts[:lines].size.to_s};0;0;#{discount_type};#{cash ? 1 : 0};1;1;#{coupon ? 1 : 0};"
    cmd += "0;0;0$x"
    cmd += "#{conv_encoding(name)}#{0xD.chr}#{join_cr(opts[:lines])}"
    cmd += CR.chr #nazwa karty
    cmd += CR.chr #nazwa czeku
    cmd += conv_encoding(opts[:coupon_name].to_s) if coupon
    cmd += CR.chr
    cmd += "#{total.to_s}/0/#{paid_in_cash}/0/0/#{coupon_value}/0/0/0/"
    send_command(cmd)
    read_and_parse
  end

  def open
    @printer = SerialPort.new(@port, @baud_rate, @data_bits, @stop_bits, @parity)
    @printer.flow_control = SerialPort::NONE
    @printer.read_timeout = 200; # domyślny timeotut w czekaniu na odpowiedź
  end

  def qr_code str
    cmd = "250$d#{str}#{0xD.chr}"
    # puts cmd
    send_command(cmd)
    read_answer
  end


  def get_version
    cmd = "#v"
    send_command(cmd)
    read_and_parse
  end

  def read_error
    cmd = '#n'
    send_command(cmd)
    ret = read_and_parse
    if ret[0] == 0x31 && ret[1] == 0x23 && ret[2] == 0x45
      @last_error = ret[3..-1].map {|b| b.chr}.join().to_i
    else
      @last_error = -1
    end
  end

  def void_receipt
    cmd = "000$e"
    send_command(cmd)
    read_and_parse
  end


  def read_answer
    str = ""
    while (true) do
      c = @printer.getbyte
      break if c.nil?
      str += c.chr
    end
    dump_string(str) if should_debug(:comm)
    str

  end

  STATUS = {
      TRF: 2 ^ 0, #bit 0: 1 - ostatnia transkacja zakonczona OK,0 - nie sfinalizowana
      PAR: 2 ^ 1 #bit 1:
  }

  def status
    # wyczyść bufor
    while (@printer.getbyte) do
    end
    @printer.write(0x5.chr)
    status = @printer.getbyte.to_i
    puts status, status.to_s(2)
    ret = {}
    STATUS.keys.each {|k| ret[k] = status & STATUS[k]}
    ret
  end

  #  private


  def join_with(lines, char)
    lines.map {|l| l.to_s + char.chr}.join();
  end

  #połącz linie znakiem CR. Jak jest jedna to na końcu też daj CR. join nie wystarczy
  def join_cr(lines)
    join_with(lines, CR)
  end

  #formatuj łańcuch z liczbą na zgodny z oczekiwnym formatem przez drukarkę
  def amount2str a
    sprintf("%0.2f", a)
  end

end


