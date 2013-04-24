class Memory
  def initialize(riot, cart, tia)
    @riot = riot
    @cart = cart
    @tia  = tia
  end

  def read(address)
    case address
    when 0x0000..0x000D then @tia.read(address)
    when 0x0080..0x00FF then @riot.read(address)
    when 0xF000..0xFFFF then @cart.read(address)
    end
  end

  def write(address, value)
    if address.between? 0x0000, 0x002C
      @tia.write(address, value)
    else
      @riot.write(address, value)
    end
  end
end
