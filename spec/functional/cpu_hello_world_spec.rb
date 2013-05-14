require 'spec_helper'

describe 'cpu hello world' do

  PF1    = 0x0E
  VBLANK = 0x01

  FRAME_END_VBLANK_VALUE = 0b01000010

  let(:cart_file) { 'spec/fixtures/files/hello.bin' }

  let :hello_world_frame do
    <<-END.gsub(/^ {5}/, '')


      X    X
      X    X
      XXXXXX
      XXXXXX
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X




      XXXXXX
      XXXXXX
      X
      X
      XXXXX
      XXXXX
      X
      X
      X
      X
      XXXXXX
      XXXXXX




      X
      X
      X
      X
      X
      X
      X
      X
      X
      X
      XXXXXX
      XXXXXX




      X
      X
      X
      X
      X
      X
      X
      X
      X
      X
      XXXXXX
      XXXXXX




       XXXX
       XXXX
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
       XXXX
       XXXX




















      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X XX X
      X XX X
       X  X
       X  X




       XXXX
       XXXX
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
      X    X
       XXXX
       XXXX




      XXXXX
      XXXXX
      X    X
      X    X
      X    X
      X    X
      XXXXX
      XXXXX
      X   X
      X   X
      X    X
      X    X




      X
      X
      X
      X
      X
      X
      X
      X
      X
      X
      XXXXXX
      XXXXXX




      XXXX
      XXXX
      X   X
      X   X
      X    X
      X    X
      X    X
      X    X
      X   X
      X   X
      XXXX
      XXXX




















    END
  end

  let :memory_with_hello_world_cart do
    cart = File.open(cart_file, "rb") { |f| f.read }
    memory = []
    memory[0xF000..0xFFFF] = cart.unpack('C*')
    memory
  end

  subject(:cpu) { Ruby2600::Cpu.new }

  before do
    cpu.memory = memory_with_hello_world_cart
    cpu.reset
    cpu.x = 0
  end

  it 'generates a frame with hello world' do
    run_one_frame_with_time_limit
    @frame.should == hello_world_frame
  end

  def run_one_frame_with_time_limit
    Timeout::timeout(1) { run_one_frame }
  end

  def run_one_frame
    @frame = ''
    @frame << scanline while cpu.memory[VBLANK] != FRAME_END_VBLANK_VALUE
  end

  def scanline
    # Could count WSYNCs, but it's easier to track X
    # (aka: the Hello World cart line counter: http://pastebin.com/abBRfUjd)
    x = cpu.x
    cpu.step while cpu.x == x
    line = sprintf("%08b", cpu.memory[PF1])
    line.gsub(/0/, ' ').gsub(/1/,'X').rstrip << "\n"
  end

end
