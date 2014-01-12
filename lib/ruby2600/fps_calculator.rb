module Ruby2600
  class FPSCalculator
    def initialize(bus, summary_frequency_frames = 10, report_frequency_seconds = 2)
      @report_frequency_seconds = report_frequency_seconds
      @summary_frequency_frames = summary_frequency_frames
      bus.instance_variable_get(:@frame_generator).
          instance_variable_set(:@frame_counter, self)
      #puts "#{Time.now}: calculating average FPS every #{report_frequency_seconds} seconds, summary frequency: #{summary_frequency_frames} frames."
    end

    def reset_counters
      @fps_start = Time.now
      @frame_count = 0
      @total_fps_start   ||= @fps_start
      @total_frame_count ||= 0
    end

    def add
      unless @fps_start
        puts "Skipping initial frame (typically bogus)"
        reset_counters
        return
      end

      now = Time.now
      puts "#{now}: Counting frame"

  	  @frame_count       += 1
      @total_frame_count += 1
  	  time_elapsed       = now - @fps_start
      total_time_elapsed = now - @total_fps_start

  	  if time_elapsed >= @report_frequency_seconds
  	  	puts "#{now}: Current: #{sprintf("%8.2f", @frame_count / time_elapsed)} FPS"
        reset_counters
  	  end

      if @total_frame_count % @summary_frequency_frames == 0
        puts "#{now}: SUMMARY: #{@total_frame_count} frames; #{sprintf("%8.2f", @total_frame_count / total_time_elapsed)} FPS"
      end
  	end
  end
end
