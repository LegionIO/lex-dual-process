# frozen_string_literal: true

module Legion
  module Extensions
    module DualProcess
      module Runners
        module DualProcess
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def register_heuristic(pattern:, domain:, response:, confidence: nil, **)
            Legion::Logging.debug "[dual_process] register_heuristic pattern=#{pattern} domain=#{domain}"
            opts = { pattern: pattern, domain: domain, response: response }
            opts[:confidence] = confidence unless confidence.nil?
            heuristic = engine.register_heuristic(**opts)
            { success: true, heuristic: heuristic.to_h }
          end

          def route_decision(query:, domain:, complexity:, **)
            Legion::Logging.debug "[dual_process] route_decision domain=#{domain} complexity=#{complexity}"
            route = engine.route_decision(query: query, domain: domain, complexity: complexity)
            { success: true, **route }
          end

          def execute_system_one(query:, domain:, **)
            Legion::Logging.debug "[dual_process] execute_system_one domain=#{domain}"
            result = engine.execute_system_one(query: query, domain: domain)
            { success: true, **result }
          end

          def execute_system_two(query:, domain:, deliberation: {}, **)
            Legion::Logging.debug "[dual_process] execute_system_two domain=#{domain}"
            result = engine.execute_system_two(query: query, domain: domain, deliberation: deliberation)
            { success: true, **result }
          end

          def record_decision_outcome(decision_id:, outcome:, **)
            Legion::Logging.debug "[dual_process] record_outcome decision_id=#{decision_id} outcome=#{outcome}"
            engine.record_outcome(decision_id: decision_id, outcome: outcome)
          end

          def effort_assessment(**)
            Legion::Logging.debug '[dual_process] effort_assessment'
            {
              success:       true,
              effort_level:  engine.effort_level,
              effort_budget: engine.instance_variable_get(:@effort_budget),
              routing_label: engine.routing_label
            }
          end

          def best_heuristics(limit: 5, **)
            Legion::Logging.debug "[dual_process] best_heuristics limit=#{limit}"
            { success: true, heuristics: engine.best_heuristics(limit: limit) }
          end

          def system_usage_stats(**)
            Legion::Logging.debug '[dual_process] system_usage_stats'
            { success: true, stats: engine.system_stats }
          end

          def update_dual_process(**)
            Legion::Logging.debug '[dual_process] update_dual_process'
            engine.recover_effort
            engine.decay_heuristics
            { success: true, effort_level: engine.effort_level, routing_label: engine.routing_label }
          end

          def dual_process_stats(**)
            Legion::Logging.debug '[dual_process] dual_process_stats'
            { success: true, **engine.to_h }
          end

          private

          def engine
            @engine ||= Helpers::DualProcessEngine.new
          end
        end
      end
    end
  end
end
