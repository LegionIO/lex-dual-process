# frozen_string_literal: true

module Legion
  module Extensions
    module DualProcess
      module Helpers
        module Constants
          MAX_DECISIONS  = 200
          MAX_HEURISTICS = 100
          MAX_HISTORY    = 300

          DEFAULT_CONFIDENCE   = 0.5
          CONFIDENCE_FLOOR     = 0.05
          CONFIDENCE_CEILING   = 0.95
          SYSTEM_ONE_THRESHOLD = 0.6
          COMPLEXITY_THRESHOLD = 0.5

          EFFORT_COST          = 0.1
          EFFORT_RECOVERY_RATE = 0.05
          MAX_EFFORT_BUDGET    = 1.0
          FATIGUE_PENALTY      = 0.15
          HEURISTIC_BOOST      = 0.2
          DECAY_RATE           = 0.01

          SYSTEMS = %i[system_one system_two].freeze

          ROUTING_LABELS = {
            (0.8..)     => :automatic,
            (0.6...0.8) => :fluent,
            (0.4...0.6) => :effortful,
            (0.2...0.4) => :strained,
            (..0.2)     => :depleted
          }.freeze

          DECISION_OUTCOMES = %i[correct incorrect uncertain].freeze
        end
      end
    end
  end
end
