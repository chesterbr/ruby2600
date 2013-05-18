require 'spec_helper'

describe 'hello world with CPU, TIA and Bus' do

  FRAME_END_VBLANK_VALUE = 0b01000010
  CART_FILE = 'spec/fixtures/files/hello.bin'

  let(:cart) { File.open(CART_FILE, "rb") { |f| f.read }.unpack('C*') }
  let(:tia)  { Ruby2600::TIA.new }
  let(:cpu)  { Ruby2600::CPU.new }
  let!(:bus) { Ruby2600::Bus.new(cpu, tia, cart, nil) }

  before do
    2.times { tia.frame } # discard the first one, most likely won't sync right
  end

  it 'generates a series of frames with hello world' do
    5.times do
      text_in(tia.frame).should == hello_world_text
    end
  end

  def text_in(frame)
    trim_blank_lines( frame.inject('') do |text_frame, scanline|
      text_frame << scanline.map{ |c| c == 0 ? " " : "X" }.join.rstrip << "\n"
    end)
  end

  def trim_blank_lines(text)
    2.times do
      text.chomp! until text.chomp == text
      text.reverse!
    end
    text
  end


  let :hello_world_text do
    trim_blank_lines <<-END

                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX




                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXXXXXXXXXXXXXXXXXX                                                            XXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXX                                                            XXXXXXXXXXXXXXXXXXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX




                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX




                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX




                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX




















                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX    XXXXXXXX    XXXX                                                        XXXX    XXXXXXXX    XXXX
                    XXXX    XXXXXXXX    XXXX                                                        XXXX    XXXXXXXX    XXXX
                        XXXX        XXXX                                                                XXXX        XXXX
                        XXXX        XXXX                                                                XXXX        XXXX




                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                        XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX




                    XXXXXXXXXXXXXXXXXXXX                                                            XXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXX                                                            XXXXXXXXXXXXXXXXXXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXXXXXXXXXXXXXXXXXX                                                            XXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXX                                                            XXXXXXXXXXXXXXXXXXXX
                    XXXX            XXXX                                                            XXXX            XXXX
                    XXXX            XXXX                                                            XXXX            XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX




                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXX                                                                            XXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXXXXXXXXXX                                                        XXXXXXXXXXXXXXXXXXXXXXXX




                    XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                    XXXX            XXXX                                                            XXXX            XXXX
                    XXXX            XXXX                                                            XXXX            XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX                XXXX                                                        XXXX                XXXX
                    XXXX            XXXX                                                            XXXX            XXXX
                    XXXX            XXXX                                                            XXXX            XXXX
                    XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX
                    XXXXXXXXXXXXXXXX                                                                XXXXXXXXXXXXXXXX

    END
  end
end
