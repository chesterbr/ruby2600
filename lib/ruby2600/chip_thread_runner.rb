module Ruby2600
  class ChipThreadRunner
    def initialize(chip)
      @chip = chip
      @running = false
      @thread = Thread.new { run }
    end

    def tick
      @running = true
      @thread.wakeup
    end

    private

    def run
      while true
        sleep while !@running
        @chip.tick
        @running = false
      end
    end
  end
end
