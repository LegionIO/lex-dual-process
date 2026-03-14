# lex-dual-process

**Level 3 Documentation** — Parent: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`

## Purpose

Dual-process cognition modeling for the LegionIO cognitive architecture. Implements Kahneman's System 1 / System 2 theory: fast heuristic reasoning vs. slow deliberative reasoning. Routes decisions to the appropriate system based on query complexity, confidence threshold, and available effort budget. Manages a library of learned heuristics that improve over time through reinforcement.

## Gem Info

- **Gem name**: `lex-dual-process`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::DualProcess`
- **Location**: `extensions-agentic/lex-dual-process/`

## File Structure

```
lib/legion/extensions/dual_process/
  dual_process.rb               # Top-level requires
  version.rb                    # VERSION = '0.1.0'
  client.rb                     # Client class
  helpers/
    constants.rb                # SYSTEM_ONE_THRESHOLD, COMPLEXITY_THRESHOLD, ROUTING_LABELS, etc.
    heuristic.rb                # Heuristic value object with reliability tracking
    decision.rb                 # Decision value object
    dual_process_engine.rb      # Engine: heuristic registry, routing, effort budget
  runners/
    dual_process.rb             # Runner module: all public methods
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `SYSTEM_ONE_THRESHOLD` | 0.6 | Minimum confidence for System 1 routing |
| `COMPLEXITY_THRESHOLD` | 0.5 | Maximum complexity for System 1 routing |
| `EFFORT_COST` | 0.1 | Effort budget consumed per System 2 decision |
| `EFFORT_RECOVERY_RATE` | 0.05 | Effort budget recovered per update cycle |
| `HEURISTIC_BOOST` | 0.2 | Confidence increase when matching heuristic exists |
| `MAX_HEURISTICS` | 100 | Heuristic registry cap |
| `MAX_DECISIONS` | 500 | Rolling decision log cap |
| `RELIABILITY_THRESHOLD` | 0.7 | Minimum success rate for a heuristic to be `reliable?` |
| `MIN_USES_FOR_RELIABILITY` | 3 | Minimum use count before reliability assessed |
| `ROUTING_LABELS` | range hash | `automatic / fluent / effortful / strained / depleted` based on effort budget |

## Runners

All methods in `Legion::Extensions::DualProcess::Runners::DualProcess`.

| Method | Key Args | Returns |
|---|---|---|
| `register_heuristic` | `pattern:, domain:, confidence: 0.7, context: {}` | `{ success:, heuristic_id:, pattern:, domain: }` |
| `route_decision` | `query:, domain:, complexity: 0.5, context: {}` | `{ success:, system:, confidence:, complexity:, heuristic_used:, effort_remaining: }` |
| `execute_system_one` | `query:, domain:, heuristic_id: nil` | `{ success:, system: :system_one, response:, confidence:, speed: }` |
| `execute_system_two` | `query:, domain:, context: {}` | `{ success:, system: :system_two, response:, confidence:, effort_cost: }` |
| `record_decision_outcome` | `decision_id:, success:` | `{ success:, decision_id:, outcome_recorded:, heuristic_updated: }` |
| `effort_assessment` | — | `{ success:, effort_budget:, effort_label:, system_bias: }` |
| `best_heuristics` | `domain: nil, limit: 5` | `{ success:, heuristics:, count: }` |
| `system_usage_stats` | — | `{ success:, system_one_count:, system_two_count:, system_one_ratio:, decisions_total: }` |
| `update_dual_process` | — | `{ success:, effort_recovered:, effort_budget: }` |
| `dual_process_stats` | — | Full stats hash including heuristic count, decision count, system usage, effort |

## Helpers

### `Heuristic`
Value object. Attributes: `id`, `pattern`, `domain`, `confidence`, `use_count`, `success_count`, `created_at`, `last_used_at`. Key methods: `reliable?` (returns true when `success_rate >= RELIABILITY_THRESHOLD` and `use_count >= MIN_USES_FOR_RELIABILITY`), `success_rate` (success_count / use_count, 0.0 when no uses), `record_use(success:)` (increments counts), `to_h`.

### `Decision`
Value object. Attributes: `id`, `query`, `domain`, `system_used`, `confidence`, `complexity`, `heuristic_id`, `outcome`, `timestamp`. `to_h`.

### `DualProcessEngine`
Central state: `@heuristics` (hash by id), `@decisions` (array, rolling), `@effort_budget` (float, 0.0–1.0). Key methods:
- `register_heuristic(...)`: validates, creates Heuristic, evicts oldest if at cap
- `route(query:, domain:, complexity:)`: checks complexity vs `COMPLEXITY_THRESHOLD`, finds matching heuristic, boosts confidence if found, routes to System 1 if `confidence >= SYSTEM_ONE_THRESHOLD` and effort not depleted
- `find_heuristic(domain:)`: returns first heuristic matching domain (simple domain match)
- `execute_system_one(query:, domain:, heuristic_id:)`: fast path, returns immediately with heuristic confidence or default
- `execute_system_two(query:, domain:, context:)`: slow path, deducts `EFFORT_COST` from budget, synthesizes response
- `record_outcome(decision_id:, success:)`: updates decision outcome, calls `heuristic.record_use(success:)` if heuristic was used
- `recover_effort`: adds `EFFORT_RECOVERY_RATE` to budget, caps at 1.0
- `effort_label`: maps budget to `ROUTING_LABELS` range

## Integration Points

- `route_decision` maps to lex-tick's `action_selection` phase — fast-paths routine actions, engages full deliberation for complex ones
- `effort_assessment[:effort_label]` feeds lex-emotion arousal (depleted effort = increased stress signal)
- `best_heuristics` supports lex-cortex's wiring decisions (which extensions to route to)
- `update_dual_process` maps to lex-tick's periodic maintenance cycle for effort recovery
- Heuristics learned from successful outcomes inform lex-prediction's forward model

## Development Notes

- System 1 routing requires both low complexity AND sufficient confidence — either alone is not enough
- Effort budget gates System 2 execution: when depleted, all decisions default to System 1
- Heuristic matching is domain-based (not semantic) — pattern field is informational, domain is the key
- Rolling decision log evicts oldest when cap is reached (not importance-based)
- `effort_label` range: `1.0–0.8 = :automatic`, `0.8–0.6 = :fluent`, `0.6–0.4 = :effortful`, `0.4–0.2 = :strained`, `0.2–0.0 = :depleted`
