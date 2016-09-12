require 'inline'

class InlineTest
  inline do |builder|
    builder.c '
      char byte(char num) {
        return num;
      }'
  end
end

i=InlineTest.new

require 'benchmark'

def byte(value)
  (value || 0) & 0xFF
end



puts Benchmark.measure {
  0.upto 100_000_000 do |num|
    byte(num)
  end
}

puts Benchmark.measure {
  0.upto 100_000_000 do |num|
    i.byte(num)
  end
}

puts i.byte(-1)
puts byte(-1)