# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module DualProcess
      module Helpers
        class Decision
          attr_accessor :outcome
          attr_reader :id, :query, :domain, :system_used, :confidence, :complexity, :heuristic_id, :effort_cost, :processing_time_ms, :created_at

          def initialize(query:, domain:, system_used:, confidence:, complexity:, **opts)
            @id                 = SecureRandom.uuid
            @query              = query
            @domain             = domain
            @system_used        = system_used
            @confidence         = confidence.clamp(Constants::CONFIDENCE_FLOOR, Constants::CONFIDENCE_CEILING)
            @complexity         = complexity.clamp(0.0, 1.0)
            @heuristic_id       = opts.fetch(:heuristic_id, nil)
            @outcome            = nil
            @effort_cost        = opts.fetch(:effort_cost, 0.0)
            @processing_time_ms = opts.fetch(:processing_time_ms, 0)
            @created_at         = Time.now.utc
          end

          def to_h
            {
              id:                 @id,
              query:              @query,
              domain:             @domain,
              system_used:        @system_used,
              confidence:         @confidence,
              complexity:         @complexity,
              heuristic_id:       @heuristic_id,
              outcome:            @outcome,
              effort_cost:        @effort_cost,
              processing_time_ms: @processing_time_ms,
              created_at:         @created_at
            }
          end
        end
      end
    end
  end
end
