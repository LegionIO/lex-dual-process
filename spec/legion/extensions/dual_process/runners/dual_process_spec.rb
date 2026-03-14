# frozen_string_literal: true

require 'legion/extensions/dual_process/client'

RSpec.describe Legion::Extensions::DualProcess::Runners::DualProcess do
  let(:client) { Legion::Extensions::DualProcess::Client.new }

  describe '#register_heuristic' do
    it 'returns success: true' do
      result = client.register_heuristic(pattern: 'hello', domain: :social, response: :wave)
      expect(result[:success]).to be true
    end

    it 'returns heuristic data' do
      result = client.register_heuristic(pattern: 'hello', domain: :social, response: :wave)
      expect(result[:heuristic]).to include(:id, :pattern, :domain, :response, :confidence)
    end

    it 'accepts custom confidence' do
      result = client.register_heuristic(pattern: :x, domain: :d, response: :r, confidence: 0.9)
      expect(result[:heuristic][:confidence]).to eq(0.9)
    end

    it 'ignores nil confidence and uses default' do
      result = client.register_heuristic(pattern: :x, domain: :d, response: :r, confidence: nil)
      expect(result[:heuristic][:confidence]).to eq(Legion::Extensions::DualProcess::Helpers::Constants::DEFAULT_CONFIDENCE)
    end
  end

  describe '#route_decision' do
    it 'returns success: true' do
      result = client.route_decision(query: 'test', domain: :work, complexity: 0.3)
      expect(result[:success]).to be true
    end

    it 'returns a system key' do
      result = client.route_decision(query: 'test', domain: :work, complexity: 0.3)
      expect(Legion::Extensions::DualProcess::Helpers::Constants::SYSTEMS).to include(result[:system])
    end

    it 'returns a reason' do
      result = client.route_decision(query: 'test', domain: :work, complexity: 0.3)
      expect(result[:reason]).not_to be_nil
    end
  end

  describe '#execute_system_one' do
    it 'returns success: true' do
      result = client.execute_system_one(query: 'test', domain: :work)
      expect(result[:success]).to be true
    end

    it 'returns system: :system_one' do
      result = client.execute_system_one(query: 'test', domain: :work)
      expect(result[:system]).to eq(:system_one)
    end

    it 'returns a decision_id' do
      result = client.execute_system_one(query: 'test', domain: :work)
      expect(result[:decision_id]).to match(/\A[0-9a-f-]{36}\z/)
    end
  end

  describe '#execute_system_two' do
    it 'returns success: true' do
      result = client.execute_system_two(query: 'complex', domain: :work)
      expect(result[:success]).to be true
    end

    it 'returns system: :system_two' do
      result = client.execute_system_two(query: 'complex', domain: :work)
      expect(result[:system]).to eq(:system_two)
    end

    it 'returns a decision_id' do
      result = client.execute_system_two(query: 'complex', domain: :work)
      expect(result[:decision_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'accepts deliberation context' do
      result = client.execute_system_two(
        query: 'complex', domain: :work,
        deliberation: { confidence: 0.9, response: :approved }
      )
      expect(result[:confidence]).to eq(0.9)
      expect(result[:response]).to eq(:approved)
    end
  end

  describe '#record_decision_outcome' do
    it 'returns success for known decision' do
      exec = client.execute_system_one(query: 'x', domain: :d)
      result = client.record_decision_outcome(decision_id: exec[:decision_id], outcome: :correct)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown decision' do
      result = client.record_decision_outcome(decision_id: 'bogus-id', outcome: :correct)
      expect(result[:success]).to be false
    end
  end

  describe '#effort_assessment' do
    it 'returns success: true' do
      result = client.effort_assessment
      expect(result[:success]).to be true
    end

    it 'includes effort_level' do
      result = client.effort_assessment
      expect(result[:effort_level]).to be_between(0.0, 1.0)
    end

    it 'includes routing_label' do
      result = client.effort_assessment
      expect(result[:routing_label]).to be_a(Symbol)
    end
  end

  describe '#best_heuristics' do
    it 'returns success: true' do
      result = client.best_heuristics
      expect(result[:success]).to be true
    end

    it 'returns heuristics array' do
      result = client.best_heuristics
      expect(result[:heuristics]).to be_an(Array)
    end

    it 'respects custom limit' do
      5.times do |i|
        client.register_heuristic(pattern: "p#{i}", domain: :d, response: :r, confidence: 0.9)
      end
      engine = client.send(:engine)
      engine.instance_variable_get(:@heuristics).each_value do |h|
        5.times { h.use!(success: true) }
      end
      result = client.best_heuristics(limit: 2)
      expect(result[:heuristics].size).to be <= 2
    end
  end

  describe '#system_usage_stats' do
    it 'returns success: true' do
      result = client.system_usage_stats
      expect(result[:success]).to be true
    end

    it 'includes stats hash' do
      result = client.system_usage_stats
      expect(result[:stats]).to include(:system_one, :system_two, :total)
    end
  end

  describe '#update_dual_process' do
    it 'returns success: true' do
      result = client.update_dual_process
      expect(result[:success]).to be true
    end

    it 'recovers effort' do
      client.execute_system_two(query: 'x', domain: :d)
      before = client.effort_assessment[:effort_level]
      client.update_dual_process
      after = client.effort_assessment[:effort_level]
      expect(after).to be >= before
    end

    it 'returns routing_label' do
      result = client.update_dual_process
      expect(result[:routing_label]).to be_a(Symbol)
    end
  end

  describe '#dual_process_stats' do
    it 'returns success: true' do
      result = client.dual_process_stats
      expect(result[:success]).to be true
    end

    it 'includes full stats' do
      result = client.dual_process_stats
      expect(result).to include(:effort_budget, :effort_level, :routing_label,
                                :heuristic_count, :decision_count, :system_stats)
    end
  end
end
