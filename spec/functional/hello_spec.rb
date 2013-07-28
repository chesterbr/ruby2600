require 'spec_helper'

describe 'hello world with CPU, TIA, Cart and Bus' do

  let(:cart) { Ruby2600::Cart.new(path_for_ROM :hello) }
  let(:tia)  { Ruby2600::TIA.new }
  let(:cpu)  { Ruby2600::CPU.new }
  let(:riot) { Ruby2600::RIOT.new }
  let!(:bus) { Ruby2600::Bus.new(cpu, tia, cart, riot) }

  it 'generates frames with hello world' do
    tia.frame # first frame won't sync, discard it
    2.times { text(tia.frame).should == hello_world_text }
  end

  def text(frame)
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
