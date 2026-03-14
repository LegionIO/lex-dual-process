# lex-dual-process

Dual-process cognition modeling for the LegionIO brain-modeled cognitive architecture.

## What It Does

Implements Kahneman's System 1 / System 2 theory. Routes decisions to fast heuristic reasoning (System 1) or slow deliberative reasoning (System 2) based on query complexity, confidence threshold, and available effort budget. Maintains a library of learned heuristics that improve through reinforcement. Models cognitive fatigue via a depletable effort budget that recovers over time.

## Usage

```ruby
client = Legion::Extensions::DualProcess::Client.new

# Register a heuristic pattern
client.register_heuristic(
  pattern: 'familiar HTTP request',
  domain: :networking,
  confidence: 0.8
)

# Route a decision — automatically selects System 1 or System 2
client.route_decision(query: 'handle incoming request', domain: :networking, complexity: 0.3)
# => { success: true, system: :system_one, confidence: 0.8, complexity: 0.3,
#      heuristic_used: "...", effort_remaining: 1.0 }

# High-complexity query forces System 2
client.route_decision(query: 'design new architecture', domain: :planning, complexity: 0.9)
# => { success: true, system: :system_two, confidence: 0.7, effort_cost: 0.1, ... }

# Record outcome to reinforce the heuristic
client.record_decision_outcome(decision_id: '...', success: true)

# Check effort budget
client.effort_assessment
# => { effort_budget: 0.8, effort_label: :fluent, system_bias: :system_one }

# Best heuristics in a domain
client.best_heuristics(domain: :networking, limit: 5)

# Periodic tick: recover effort budget
client.update_dual_process
# => { success: true, effort_recovered: 0.05, effort_budget: 0.85 }
```

## Routing Labels

| Effort Budget | Label |
|---|---|
| 0.8 – 1.0 | `:automatic` |
| 0.6 – 0.8 | `:fluent` |
| 0.4 – 0.6 | `:effortful` |
| 0.2 – 0.4 | `:strained` |
| 0.0 – 0.2 | `:depleted` |

When effort is depleted, all decisions route to System 1 regardless of complexity.

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
