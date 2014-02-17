module Ruby2600
  class Cart
    def initialize(rom)
      if rom.is_a? Array
        @bytes = rom
      else
        @bytes = File.open(rom.to_s, "rb") { |f| f.read }.unpack('C*')
      end
      @bytes += @bytes if @bytes.count == 2048
    end

    def [](address)
      @bytes[address]
    end

    def []=(address, value)
    end
  end
end
