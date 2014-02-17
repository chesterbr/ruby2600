require 'spec_helper'
require 'fixtures/cart_arrays'

describe 'diagonal drawn with stetched missile and HMOV' do

  let(:cart) { Ruby2600::Cart.new(DIAGONAL_HMOV_CART_ARRAY) }
  let(:tia)  { Ruby2600::TIA.new }
  let(:cpu)  { Ruby2600::CPU.new }
  let(:riot) { Ruby2600::RIOT.new }
  let!(:bus) { Ruby2600::Bus.new(cpu, tia, cart, riot) }

  it 'draws the diagonal' do
    pending 'adjust the off-by-one drawing'
    tia.frame # first frame won't sync, discard it
    2.times { expect(text(tia.frame)).to eq(hello_world_text) }
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
                                                                                                                                                            XXXX
                                                                                                                                                             XXX
                                                                                                                                                              XX
                                                                                                                                                               X

        X
        XX
        XXX
        XXXX
        XXXXX
        XXXXXX
        XXXXXXX
        XXXXXXXX
         XXXXXXXX
          XXXXXXXX
           XXXXXXXX
            XXXXXXXX
             XXXXXXXX
              XXXXXXXX
               XXXXXXXX
                XXXXXXXX
                 XXXXXXXX
                  XXXXXXXX
                   XXXXXXXX
                    XXXXXXXX
                     XXXXXXXX
                      XXXXXXXX
                       XXXXXXXX
                        XXXXXXXX
                         XXXXXXXX
                          XXXXXXXX
                           XXXXXXXX
                            XXXXXXXX
                             XXXXXXXX
                              XXXXXXXX
                               XXXXXXXX
                                XXXXXXXX
                                 XXXXXXXX
                                  XXXXXXXX
                                   XXXXXXXX
                                    XXXXXXXX
                                     XXXXXXXX
                                      XXXXXXXX
                                       XXXXXXXX
                                        XXXXXXXX
                                         XXXXXXXX
                                          XXXXXXXX
                                           XXXXXXXX
                                            XXXXXXXX
                                             XXXXXXXX
                                              XXXXXXXX
                                               XXXXXXXX
                                                XXXXXXXX
                                                 XXXXXXXX
                                                  XXXXXXXX
                                                   XXXXXXXX
                                                    XXXXXXXX
                                                     XXXXXXXX
                                                      XXXXXXXX
                                                       XXXXXXXX
                                                        XXXXXXXX
                                                         XXXXXXXX
                                                          XXXXXXXX
                                                           XXXXXXXX
                                                            XXXXXXXX
                                                             XXXXXXXX
                                                              XXXXXXXX
                                                               XXXXXXXX
                                                                XXXXXXXX
                                                                 XXXXXXXX
                                                                  XXXXXXXX
                                                                   XXXXXXXX
                                                                    XXXXXXXX
                                                                     XXXXXXXX
                                                                      XXXXXXXX
                                                                       XXXXXXXX
                                                                        XXXXXXXX
                                                                         XXXXXXXX
                                                                          XXXXXXXX
                                                                           XXXXXXXX
                                                                            XXXXXXXX
                                                                             XXXXXXXX
                                                                              XXXXXXXX
                                                                               XXXXXXXX
                                                                                XXXXXXXX
                                                                                 XXXXXXXX
                                                                                  XXXXXXXX
                                                                                   XXXXXXXX
                                                                                    XXXXXXXX
                                                                                     XXXXXXXX
                                                                                      XXXXXXXX
                                                                                       XXXXXXXX
                                                                                        XXXXXXXX
                                                                                         XXXXXXXX
                                                                                          XXXXXXXX
                                                                                           XXXXXXXX
                                                                                            XXXXXXXX
                                                                                             XXXXXXXX
                                                                                              XXXXXXXX
                                                                                               XXXXXXXX
                                                                                                XXXXXXXX
                                                                                                 XXXXXXXX
                                                                                                  XXXXXXXX
                                                                                                   XXXXXXXX
                                                                                                    XXXXXXXX
                                                                                                     XXXXXXXX
                                                                                                      XXXXXXXX
                                                                                                       XXXXXXXX
                                                                                                        XXXXXXXX
                                                                                                         XXXXXXXX
                                                                                                          XXXXXXXX
                                                                                                           XXXXXXXX
                                                                                                            XXXXXXXX
                                                                                                             XXXXXXXX
                                                                                                              XXXXXXXX
                                                                                                               XXXXXXXX
                                                                                                                XXXXXXXX
                                                                                                                 XXXXXXXX
                                                                                                                  XXXXXXXX
                                                                                                                   XXXXXXXX
                                                                                                                    XXXXXXXX
                                                                                                                     XXXXXXXX
                                                                                                                      XXXXXXXX
                                                                                                                       XXXXXXXX
                                                                                                                        XXXXXXXX
                                                                                                                         XXXXXXXX
                                                                                                                          XXXXXXXX
                                                                                                                           XXXXXXXX
                                                                                                                            XXXXXXXX
                                                                                                                             XXXXXXXX
                                                                                                                              XXXXXXXX
                                                                                                                               XXXXXXXX
                                                                                                                                XXXXXXXX
                                                                                                                                 XXXXXXXX
                                                                                                                                  XXXXXXXX
                                                                                                                                   XXXXXXXX
                                                                                                                                    XXXXXXXX
                                                                                                                                     XXXXXXXX
                                                                                                                                      XXXXXXXX
                                                                                                                                       XXXXXXXX
                                                                                                                                        XXXXXXXX
                                                                                                                                         XXXXXXXX
                                                                                                                                          XXXXXXXX
                                                                                                                                           XXXXXXXX
                                                                                                                                            XXXXXXXX
                                                                                                                                             XXXXXXXX
                                                                                                                                              XXXXXXXX
                                                                                                                                               XXXXXXXX
                                                                                                                                                XXXXXXXX
                                                                                                                                                 XXXXXXXX
                                                                                                                                                  XXXXXXXX
                                                                                                                                                   XXXXXXXX
                                                                                                                                                    XXXXXXXX
                                                                                                                                                     XXXXXXXX
                                                                                                                                                      XXXXXXXX
                                                                                                                                                       XXXXXXXX
                                                                                                                                                        XXXXXXXX
                                                                                                                                                         XXXXXXX
                                                                                                                                                          XXXXXX
                                                                                                                                                           XXXXX
                                                                                                                                                            XXXX
                                                                                                                                                             XXX
                                                                                                                                                              XX
                                                                                                                                                               X

        X
        XX
        XXX
        XXXX
        XXXXX
        XXXXXX
        XXXXXXX
        XXXXXXXX
         XXXXXXXX
          XXXXXXXX
           XXXXXXXX
            XXXXXXXX
             XXXXXXXX
              XXXXXXXX
               XXXXXXXX
                XXXXXXXX
                 XXXXXXXX
                  XXXXXXXX
                   XXXXXXXX
                    XXXXXXXX
                     XXXXXXXX
                      XXXXXXXX
                       XXXXXXXX
                        XXXXXXXX
                         XXXXXXXX
                          XXXXXXXX
    END
  end
end
