# frozen_string_literal: true

RSpec.describe Legion::Extensions::DualProcess::Helpers::DualProcessEngine do
  subject(:engine) { described_class.new }

  describe '#initialize' do
    it 'starts with full effort budget' do
      expect(engine.effort_level).to eq(1.0)
    end

    it 'starts with no heuristics' do
      expect(engine.system_stats[:total]).to eq(0)
    end
  end

  describe '#register_heuristic' do
    it 'returns a Heuristic object' do
      h = engine.register_heuristic(pattern: 'hello', domain: :social, response: :wave)
      expect(h).to be_a(Legion::Extensions::DualProcess::Helpers::Heuristic)
    end

    it 'stores the heuristic' do
      engine.register_heuristic(pattern: 'hello', domain: :social, response: :wave)
      expect(engine.to_h[:heuristic_count]).to eq(1)
    end

    it 'accepts custom confidence' do
      h = engine.register_heuristic(pattern: :x, domain: :d, response: :r, confidence: 0.8)
      expect(h.confidence).to eq(0.8)
    end

    it 'evicts oldest when at capacity' do
      stub_const('Legion::Extensions::DualProcess::Helpers::Constants::MAX_HEURISTICS', 2)
      h1 = engine.register_heuristic(pattern: 'a', domain: :d, response: :r1)
      h2 = engine.register_heuristic(pattern: 'b', domain: :d, response: :r2)
      engine.register_heuristic(pattern: 'c', domain: :d, response: :r3)
      ids = [h1.id, h2.id]
      expect(engine.to_h[:heuristic_count]).to eq(2)
      # one of the originals was evicted
      expect(ids.count { |id| engine.instance_variable_get(:@heuristics).key?(id) }).to be <= 1
    end
  end

  describe '#route_decision' do
    context 'with a matching confident heuristic and low complexity' do
      before do
        engine.register_heuristic(pattern: 'hello', domain: :social, response: :wave, confidence: 0.8)
      end

      it 'routes to system_one' do
        result = engine.route_decision(query: 'say hello', domain: :social, complexity: 0.2)
        expect(result[:system]).to eq(:system_one)
        expect(result[:reason]).to eq(:heuristic_match)
      end
    end

    context 'with high complexity' do
      it 'routes to system_two' do
        result = engine.route_decision(query: 'complex decision', domain: :work, complexity: 0.8)
        expect(result[:system]).to eq(:system_two)
      end
    end

    context 'with no matching heuristic and low complexity' do
      it 'routes to system_two due to no heuristic' do
        result = engine.route_decision(query: 'unknown query', domain: :work, complexity: 0.3)
        expect(result[:system]).to eq(:system_two)
        expect(result[:reason]).to eq(:no_heuristic)
      end
    end

    context 'when effort is depleted' do
      before do
        stub_const('Legion::Extensions::DualProcess::Helpers::Constants::MAX_EFFORT_BUDGET', 0.0)
        engine.instance_variable_set(:@effort_budget, 0.0)
      end

      it 'forces system_one with fatigue flag' do
        result = engine.route_decision(query: 'complex', domain: :work, complexity: 0.9)
        expect(result[:system]).to eq(:system_one)
        expect(result[:reason]).to eq(:effort_depleted)
        expect(result[:fatigue]).to be true
      end
    end
  end

  describe '#execute_system_one' do
    context 'with a matching heuristic' do
      before do
        engine.register_heuristic(pattern: 'hello', domain: :social, response: :wave, confidence: 0.8)
      end

      it 'returns the heuristic response' do
        result = engine.execute_system_one(query: 'say hello', domain: :social)
        expect(result[:response]).to eq(:wave)
        expect(result[:system]).to eq(:system_one)
      end

      it 'includes decision_id' do
        result = engine.execute_system_one(query: 'say hello', domain: :social)
        expect(result[:decision_id]).to match(/\A[0-9a-f-]{36}\z/)
      end
    end

    context 'without a matching heuristic' do
      it 'returns :no_heuristic response' do
        result = engine.execute_system_one(query: 'unknown', domain: :work)
        expect(result[:response]).to eq(:no_heuristic)
      end

      it 'applies fatigue penalty to confidence' do
        result = engine.execute_system_one(query: 'unknown', domain: :work)
        expected = (Legion::Extensions::DualProcess::Helpers::Constants::DEFAULT_CONFIDENCE -
                    Legion::Extensions::DualProcess::Helpers::Constants::FATIGUE_PENALTY)
        expect(result[:confidence]).to be_within(0.001).of(expected)
      end
    end
  end

  describe '#execute_system_two' do
    it 'deducts effort from the budget' do
      before_effort = engine.effort_level
      engine.execute_system_two(query: 'complex', domain: :work)
      expect(engine.effort_level).to be < before_effort
    end

    it 'returns a decision_id' do
      result = engine.execute_system_two(query: 'complex', domain: :work)
      expect(result[:decision_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns system_two' do
      result = engine.execute_system_two(query: 'complex', domain: :work)
      expect(result[:system]).to eq(:system_two)
    end

    it 'uses deliberation confidence when provided' do
      result = engine.execute_system_two(query: 'x', domain: :d, deliberation: { confidence: 0.85 })
      expect(result[:confidence]).to eq(0.85)
    end

    it 'uses deliberation response when provided' do
      result = engine.execute_system_two(query: 'x', domain: :d, deliberation: { response: :approve })
      expect(result[:response]).to eq(:approve)
    end

    it 'does not go below zero effort' do
      15.times { engine.execute_system_two(query: 'x', domain: :d) }
      expect(engine.effort_level).to be >= 0.0
    end
  end

  describe '#record_outcome' do
    let(:decision_id) do
      engine.execute_system_one(query: 'test', domain: :work)[:decision_id]
    end

    it 'returns success for known decision' do
      result = engine.record_outcome(decision_id: decision_id, outcome: :correct)
      expect(result[:success]).to be true
    end

    it 'returns not_found for unknown decision' do
      result = engine.record_outcome(decision_id: 'nonexistent', outcome: :correct)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'rejects invalid outcome values' do
      result = engine.record_outcome(decision_id: decision_id, outcome: :success)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:invalid_outcome)
    end

    it 'returns valid outcomes in the error' do
      result = engine.record_outcome(decision_id: decision_id, outcome: :bad)
      expect(result[:valid]).to eq(Legion::Extensions::DualProcess::Helpers::Constants::DECISION_OUTCOMES)
    end

    it 'accepts :correct outcome' do
      result = engine.record_outcome(decision_id: decision_id, outcome: :correct)
      expect(result[:success]).to be true
    end

    it 'accepts :incorrect outcome' do
      result = engine.record_outcome(decision_id: decision_id, outcome: :incorrect)
      expect(result[:success]).to be true
    end

    it 'accepts :uncertain outcome' do
      result = engine.record_outcome(decision_id: decision_id, outcome: :uncertain)
      expect(result[:success]).to be true
    end
  end

  describe '#effort_level' do
    it 'starts at 1.0' do
      expect(engine.effort_level).to eq(1.0)
    end

    it 'decreases after system_two execution' do
      engine.execute_system_two(query: 'x', domain: :d)
      expect(engine.effort_level).to be < 1.0
    end
  end

  describe '#routing_label' do
    it 'returns :automatic at full effort' do
      expect(engine.routing_label).to eq(:automatic)
    end

    it 'returns :depleted at very low effort' do
      engine.instance_variable_set(:@effort_budget, 0.1)
      expect(engine.routing_label).to eq(:depleted)
    end

    it 'returns :effortful at mid effort' do
      engine.instance_variable_set(:@effort_budget, 0.5)
      expect(engine.routing_label).to eq(:effortful)
    end
  end

  describe '#recover_effort' do
    it 'increases effort budget' do
      engine.execute_system_two(query: 'x', domain: :d)
      before = engine.effort_level
      engine.recover_effort
      expect(engine.effort_level).to be > before
    end

    it 'does not exceed MAX_EFFORT_BUDGET' do
      5.times { engine.recover_effort }
      expect(engine.effort_level).to be <= 1.0
    end
  end

  describe '#decay_heuristics' do
    it 'reduces confidence of used heuristics' do
      h = engine.register_heuristic(pattern: 'x', domain: :d, response: :r, confidence: 0.8)
      h.use!(success: true)
      before = h.confidence
      engine.decay_heuristics
      expect(h.confidence).to be < before
    end

    it 'does not decay unused heuristics' do
      h = engine.register_heuristic(pattern: 'x', domain: :d, response: :r, confidence: 0.8)
      before = h.confidence
      engine.decay_heuristics
      expect(h.confidence).to eq(before)
    end
  end

  describe '#system_stats' do
    it 'returns zeros with no decisions' do
      stats = engine.system_stats
      expect(stats[:total]).to eq(0)
      expect(stats[:s1_ratio]).to eq(0.0)
    end

    it 'counts system_one and system_two decisions separately' do
      engine.execute_system_one(query: 'x', domain: :d)
      engine.execute_system_two(query: 'y', domain: :d)
      stats = engine.system_stats
      expect(stats[:system_one]).to eq(1)
      expect(stats[:system_two]).to eq(1)
      expect(stats[:total]).to eq(2)
    end
  end

  describe '#best_heuristics' do
    it 'returns empty array with no reliable heuristics' do
      expect(engine.best_heuristics(limit: 5)).to eq([])
    end

    it 'returns reliable heuristics sorted by success_rate' do
      h = engine.register_heuristic(pattern: 'x', domain: :d, response: :r, confidence: 0.9)
      5.times { h.use!(success: true) }
      result = engine.best_heuristics(limit: 5)
      expect(result.size).to eq(1)
      expect(result.first[:id]).to eq(h.id)
    end

    it 'respects the limit' do
      3.times do |i|
        h = engine.register_heuristic(pattern: "p#{i}", domain: :d, response: :r, confidence: 0.9)
        5.times { h.use!(success: true) }
      end
      expect(engine.best_heuristics(limit: 2).size).to eq(2)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      result = engine.to_h
      expect(result).to include(:effort_budget, :effort_level, :routing_label,
                                :heuristic_count, :decision_count, :system_stats)
    end
  end
end
