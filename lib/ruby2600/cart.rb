module Ruby2600
  class Cart
    def initialize(rom_file)
      @bytes = File.open(rom_file, "rb") { |f| f.read }.unpack('C*')
      @bytes += @bytes if @bytes.count == 2048
    end

    def [](address)
      @bytes[address]
    end

    def []=(address, value)
    end
  end
end
