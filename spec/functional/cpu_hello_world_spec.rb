require 'spec_helper'

describe 'hello world with CPU, TIA and Bus' do

  FRAME_END_VBLANK_VALUE = 0b01000010
  CART_FILE = 'spec/fixtures/files/hello.bin'

  let(:cart) { File.open(CART_FILE, "rb") { |f| f.read }.unpack('C*') }
  let(:tia)  { Ruby2600::TIA.new }
  let(:cpu)  { Ruby2600::CPU.new }
  let!(:bus) { Ruby2600::Bus.new(cpu, tia, cart, nil) }

  it 'generates a frame with hello world' do
    # FIXME should really wait for VBLANK, or use a higher-level frame
    # generation from TIA (better)
    frame = ''
    1.upto(40)  { tia.scanline } # skip VBLANK/VSYNC
    1.upto(176) { frame << as_text(tia.scanline) }
    frame.should == hello_world_frame
  end

  def as_text(scanline)
    scanline.map{ |c| c == 0 ? " " : "X" }.join.rstrip << "\n"
  end


  let :hello_world_frame do
    <<-END


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
