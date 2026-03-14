# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module DualProcess
      module Helpers
        class Heuristic
          attr_reader :id, :pattern, :domain, :response, :confidence,
                      :use_count, :success_count, :created_at, :last_used_at

          def initialize(pattern:, domain:, response:, confidence: Constants::DEFAULT_CONFIDENCE)
            @id            = SecureRandom.uuid
            @pattern       = pattern
            @domain        = domain
            @response      = response
            @confidence    = confidence.clamp(Constants::CONFIDENCE_FLOOR, Constants::CONFIDENCE_CEILING)
            @use_count     = 0
            @success_count = 0
            @created_at    = Time.now.utc
            @last_used_at  = nil
          end

          def use!(success: true)
            @use_count    += 1
            @last_used_at  = Time.now.utc
            @success_count += 1 if success

            delta = success ? Constants::HEURISTIC_BOOST : -Constants::HEURISTIC_BOOST
            @confidence = (@confidence + delta).clamp(Constants::CONFIDENCE_FLOOR, Constants::CONFIDENCE_CEILING)
          end

          def success_rate
            return 0.0 if @use_count.zero?

            @success_count.to_f / @use_count
          end

          def reliable?
            success_rate >= 0.7 && @use_count >= 3
          end

          def to_h
            {
              id:            @id,
              pattern:       @pattern,
              domain:        @domain,
              response:      @response,
              confidence:    @confidence,
              use_count:     @use_count,
              success_count: @success_count,
              success_rate:  success_rate,
              reliable:      reliable?,
              created_at:    @created_at,
              last_used_at:  @last_used_at
            }
          end
        end
      end
    end
  end
end
