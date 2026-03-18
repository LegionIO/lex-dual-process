# frozen_string_literal: true

module Legion
  module Extensions
    module DualProcess
      module Helpers
        class DualProcessEngine
          include Constants

          def initialize
            @effort_budget = MAX_EFFORT_BUDGET
            @heuristics    = {}
            @decisions     = []
          end

          def register_heuristic(pattern:, domain:, response:, confidence: DEFAULT_CONFIDENCE)
            heuristic = Heuristic.new(pattern: pattern, domain: domain, response: response, confidence: confidence)
            if @heuristics.size >= MAX_HEURISTICS
              oldest_key = @heuristics.min_by { |_, h| h.last_used_at || h.created_at }.first
              @heuristics.delete(oldest_key)
            end
            @heuristics[heuristic.id] = heuristic
            heuristic
          end

          def route_decision(query:, domain:, complexity:)
            matching = find_matching_heuristic(query, domain)
            use_system_one = complexity < COMPLEXITY_THRESHOLD &&
                             matching &&
                             matching.confidence >= SYSTEM_ONE_THRESHOLD

            if use_system_one
              { system: :system_one, reason: :heuristic_match, heuristic_id: matching.id }
            elsif @effort_budget >= EFFORT_COST
              { system: :system_two, reason: complexity_reason(complexity, matching) }
            else
              { system: :system_one, reason: :effort_depleted, fatigue: true }
            end
          end

          def execute_system_one(query:, domain:)
            matching = find_matching_heuristic(query, domain)
            start    = Process.clock_gettime(Process::CLOCK_MONOTONIC)

            if matching
              matching.use!(success: true)
              confidence = matching.confidence
              response   = matching.response
            else
              confidence = (DEFAULT_CONFIDENCE - FATIGUE_PENALTY).clamp(CONFIDENCE_FLOOR, CONFIDENCE_CEILING)
              response   = :no_heuristic
            end

            elapsed = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

            decision = Decision.new(
              query:              query,
              domain:             domain,
              system_used:        :system_one,
              confidence:         confidence,
              complexity:         0.0,
              heuristic_id:       matching&.id,
              effort_cost:        0.0,
              processing_time_ms: elapsed
            )
            store_decision(decision)
            { decision_id: decision.id, system: :system_one, response: response, confidence: confidence }
          end

          def execute_system_two(query:, domain:, deliberation: {})
            start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
            @effort_budget = (@effort_budget - EFFORT_COST).clamp(0.0, MAX_EFFORT_BUDGET)

            confidence = deliberation.fetch(:confidence, DEFAULT_CONFIDENCE + HEURISTIC_BOOST)
                                     .clamp(CONFIDENCE_FLOOR, CONFIDENCE_CEILING)
            response   = deliberation.fetch(:response, :deliberated)
            elapsed    = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

            decision = Decision.new(
              query:              query,
              domain:             domain,
              system_used:        :system_two,
              confidence:         confidence,
              complexity:         deliberation.fetch(:complexity, COMPLEXITY_THRESHOLD),
              effort_cost:        EFFORT_COST,
              processing_time_ms: elapsed
            )
            store_decision(decision)
            { decision_id: decision.id, system: :system_two, response: response, confidence: confidence }
          end

          def record_outcome(decision_id:, outcome:)
            return { success: false, reason: :invalid_outcome, valid: DECISION_OUTCOMES } unless DECISION_OUTCOMES.include?(outcome)

            decision = @decisions.find { |d| d.id == decision_id }
            return { success: false, reason: :not_found } unless decision

            decision.outcome = outcome

            if decision.heuristic_id
              heuristic = @heuristics[decision.heuristic_id]
              heuristic&.use!(success: outcome == :correct)
            end

            { success: true, decision_id: decision_id, outcome: outcome }
          end

          def effort_level
            @effort_budget / MAX_EFFORT_BUDGET
          end

          def routing_label
            ROUTING_LABELS.find { |range, _| range.cover?(effort_level) }&.last || :unknown
          end

          def recover_effort
            @effort_budget = (@effort_budget + EFFORT_RECOVERY_RATE).clamp(0.0, MAX_EFFORT_BUDGET)
          end

          def decay_heuristics
            @heuristics.each_value do |h|
              next unless h.use_count.positive?

              delta = -DECAY_RATE
              h.instance_variable_set(:@confidence, (h.confidence + delta).clamp(CONFIDENCE_FLOOR, CONFIDENCE_CEILING))
            end
          end

          def system_stats
            s1 = @decisions.count { |d| d.system_used == :system_one }
            s2 = @decisions.count { |d| d.system_used == :system_two }
            total = @decisions.size

            {
              system_one: s1,
              system_two: s2,
              total:      total,
              s1_ratio:   total.zero? ? 0.0 : (s1.to_f / total).round(3),
              s2_ratio:   total.zero? ? 0.0 : (s2.to_f / total).round(3)
            }
          end

          def best_heuristics(limit: 5)
            @heuristics.values
                       .select(&:reliable?)
                       .sort_by { |h| [-h.success_rate, -h.use_count] }
                       .first(limit)
                       .map(&:to_h)
          end

          def to_h
            {
              effort_budget:   @effort_budget,
              effort_level:    effort_level,
              routing_label:   routing_label,
              heuristic_count: @heuristics.size,
              decision_count:  @decisions.size,
              system_stats:    system_stats
            }
          end

          private

          def find_matching_heuristic(query, domain)
            @heuristics.values
                       .select { |h| h.domain == domain || domain.nil? }
                       .select { |h| query_matches?(h.pattern, query) }
                       .max_by(&:confidence)
          end

          def query_matches?(pattern, query)
            case pattern
            when Symbol then query.is_a?(Hash) && query.key?(pattern)
            when String then query.to_s.include?(pattern)
            when Regexp then pattern.match?(query.to_s)
            else false
            end
          end

          def complexity_reason(complexity, matching)
            if complexity >= COMPLEXITY_THRESHOLD
              :high_complexity
            elsif matching.nil?
              :no_heuristic
            else
              :low_confidence
            end
          end

          def store_decision(decision)
            @decisions.shift if @decisions.size >= MAX_DECISIONS
            @decisions << decision
          end
        end
      end
    end
  end
end
