module EmarTempoComm

  def self.included(klass)
    klass.extend ClassMethods
  end
  module ClassMethods
    def CRCsum str
      sum = 255
      str.each_char do |b|
        sum = sum ^ b.ord
      end
      sum
    end
  end
  CR = 0xD

  MAZOVIA_HASH = {
      'Ą'.ord => 0x8F, #Ą
      'µ'.ord => 0xe6,
      'Ω'.ord => 0xEA,
      '²'.ord => 0xFD,
      0x106 => 0x95, #Ć
      0x118 => 0x90, #Ę
      0x141 => 0x9C, #Ł
      0x143 => 0xA5, #Ń
      'Ó'.ord => 0xA3, #Ó
      0x15A => 0x98, #Ś
      0x179 => 0xA0, #Ź
      0x17B => 0xA1, #Ż
      0x105 => 0x86, #ą
      0x107 => 0x8D, #ć
      0x119 => 0x91, #ę
      0x142 => 0x92, #ł
      0x144 => 0xA4, #ń
      0xF3 => 0xA2, #ó
      0x15B => 0x9E, #ś
      0x17A => 0xA6, #ź
      0x17C => 0xA7 #ż
  }



  def send_command data
    crc = EmarTempoPrinter.CRCsum(data).to_s(16).upcase
    crc = "0#{crc}" if crc.length < 2
    # puts crc
    str = ""
    str += 27.chr
    str += 'P'
    data.each_byte {|b| str += b.chr}
    crc.each_byte {|b| str += b.chr}
    str += 27.chr
    str += '\\'
    @printer.write(str)
    dump_string(str) if should_debug(:comm)
    # @printer.write(0x27.chr)
    # @printer.write('P')
    # data.each_byte {|b| @printer.write(b.chr)}
    # crc.each_byte {|b| @printer.write(b.chr)}
    # @printer.write(0x27.chr)
    # @printer.write('\\')

  end

  def read_and_parse
    answ = read_answer
    ret = parse_answer(answ)
    puts "Read&Parse:#{ret.join(',')}" if should_debug(:comm)
    ret
  end

  def dump_string str
    puts str.each_byte.collect {|b| byte_to_ascii(b)}.join(' ')
    puts str.each_byte.collect {|b| b.to_s(16)}.join(",")
    # hex = []
    # chr = []
    # i = 0
    # str.each_byte {|b|
    #   hex[i] = sprintf("%2.X", b)
    #   chr[i] = byte_to_ascii(b)
    #   if i == 11
    #     i = -1
    #     print hex.join(" ")
    #     print "|"
    #     print chr.join('')
    #     puts "|"
    #
    #   end
    #   i += 1
    # }
    # puts
  end


  #pomocnicza funkcja zamienajaca bajt na znak ascii. Robi ładne znaki sterujace
  # 0x27 -> <ESC>
  def byte_to_ascii b
    case b
    when 0x27
      return "<ESC>"
    when 0x0D
      return "<CR>"
    when 0..19
      return '.'
    else
      return b.chr
    end
  end

  def parse_answer answ
    state = :blank
    arr = answ.each_byte.collect {|b| b}
    ret = []
    idx = -1
    while (true) do
      idx += 1
      return [] if idx >= arr.size # jesli wyjdziemy poza odpowiedź to źle
      puts "IDX:#{idx}, arr:#{arr[idx]} - #{arr[idx].chr}" if should_debug(:parsing)

      if state == :blank && arr[idx] == 0x1B
        puts "IDX:#{idx} #{state} -> esc_start" if should_debug(:parsing)
        state = :esc_start
        next
      end

      if :esc_start == state
        if 'P' == arr[idx].chr
          puts "IDX:#{idx} #{state} -> parsing" if should_debug(:parsing)
          state = :parsing
        else
          puts "IDX:#{idx} #{state} -> blank" if should_debug(:parsing)
          state = :blank #po ESC na początku ma być P
        end
        next
      end

      if :parsing == state
        if 0x1B == arr[idx]
          puts "IDX:#{idx} #{state} -> closing" if should_debug(:parsing)
          state = :closing
        else
          ret << arr[idx]
        end
        next
      end

      if :closing == state
        if '\\' == arr[idx].chr
          puts "IDX:#{idx} KONIEC" if should_debug(:parsing)
          return ret #koniec
        else
          state = :parsing #to było zwykłe ESC w kodzie. Czy w ogole możliwie?
          puts "IDX:#{idx} #{state} -> parsing" if should_debug(:parsing)
          ret << 0x1B
          ret << arr[idx]
        end
        next
      end
    end
  end

  def should_debug(atr)
    return true if @debug.include?(:all)
    return @debug.include?(atr)
  end

  def start_debug atr
    debug << atr
  end

  def stop_debug atr
    debug.delete atr
  end

  def debug?
    return !@debug.nil? && @debug != []
  end

  def debug
    return @debug
  end

end