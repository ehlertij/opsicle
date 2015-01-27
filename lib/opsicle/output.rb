require 'highline'

module Opsicle
  module Output
    def self.terminal
      HighLine.color_scheme = color_scheme
      @terminal ||= HighLine.new
    end

    def self.color_scheme
      @color_scheme ||= HighLine::ColorScheme.new(
          :normal => [],
          :error => [:bold, :red],
          :warning => [:bold, :yellow],
          :verbose => [:bold, :magenta],
          :debug => [:bold, :cyan],
          :success => [:bold, :green],
      )
    end

    def self.say(msg, log_style=:normal)
      if $color
        terminal.say "<%= color('#{msg}', '#{log_style}') %>"
      else
        terminal.say msg
      end
    end

    def self.say_verbose(msg)
      terminal.say "<%= color('#{msg}', 'verbose') %>" if $verbose
    end

    def self.ask(*args, &block)
      terminal.ask(*args, &block)
    end
  end
end
