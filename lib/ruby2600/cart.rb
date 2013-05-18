module Ruby2600
  class Cart
    def initialize(rom_file)
      @bytes = File.open(rom_file, "rb") { |f| f.read }.unpack('C*')
    end

    def [](address)
      @bytes[address]
    end

    def []=(address, value)
    end
  end
end
