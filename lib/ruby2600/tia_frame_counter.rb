module Ruby2600
  class TIAFrameCounter
  	FPS_DISPLAY_INTERVAL_SECONDS = 2

    def self.hook(tia)
      tia.instance_variable_set(:@frame_counter, TIAFrameCounter.new)
    end

    def reset_fps
      @fps_start = Time.now
      @fps_count = 0
    end

    def track_fps
      reset_fps and return unless @fps_start

  	  @fps_count += 1
  	  time_elapsed = Time.now - @fps_start
  	  if time_elapsed >= FPS_DISPLAY_INTERVAL_SECONDS
  	  	puts "#{Time.now}: #{@fps_count / time_elapsed} frames per second."
        reset_fps
  	  end
  	end
  end
end
