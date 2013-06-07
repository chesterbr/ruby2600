module Ruby2600
  class RIOT
    attr_accessor :ram

    def initialize
      @ram = Array.new(128)
    end
  end
end
