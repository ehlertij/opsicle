module Opsicle
  module Monitor
    module Panels
      class Deployments < Monitor::Panel

        def initialize(height, width, top, left)
          super(height, width, top, left, structure(height), :divider_r => " ")

          @spies[:deployments] = Monitor::Spy::Deployments.new
        end

        def structure(height)
          # [
          #   [relative_column_width, data_left, data_right]
          # ]
          s = [
            [ # table header slots
              [1, t[:heading][:status], nil],
              [1, t[:heading][:created_at], nil],
              [1, t[:heading][:completed_at], nil],
              [1, t[:heading][:user], nil],
              [1, t[:heading][:command], nil],
              [1, t[:heading][:app_id], nil],
            ],
          ]

          (0...(height - 1)).each do |i|
            s << [ # table row slots
              [1, -> { @spies[:deployments][i][:status] },  nil],
              [1, -> { @spies[:deployments][i][:created_at] },  nil],
              [1, -> { @spies[:deployments][i][:completed_at] },  nil],
              [1, -> { @spies[:deployments][i][:user] }, nil],
              [1, -> { @spies[:deployments][i][:command] }, nil],
              [1, -> { @spies[:deployments][i][:app_id] },  nil],
            ]
          end

          s
        end

      end
    end
  end
end
