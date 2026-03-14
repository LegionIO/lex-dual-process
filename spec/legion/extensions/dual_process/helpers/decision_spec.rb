# frozen_string_literal: true

RSpec.describe Legion::Extensions::DualProcess::Helpers::Decision do
  let(:decision) do
    described_class.new(
      query:       'should I wave?',
      domain:      :social,
      system_used: :system_one,
      confidence:  0.75,
      complexity:  0.3
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(decision.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores core fields' do
      expect(decision.query).to eq('should I wave?')
      expect(decision.domain).to eq(:social)
      expect(decision.system_used).to eq(:system_one)
    end

    it 'clamps confidence to valid range' do
      d = described_class.new(query: 'x', domain: :d, system_used: :system_one, confidence: 2.0, complexity: 0.5)
      expect(d.confidence).to eq(Legion::Extensions::DualProcess::Helpers::Constants::CONFIDENCE_CEILING)
    end

    it 'clamps complexity to [0, 1]' do
      d = described_class.new(query: 'x', domain: :d, system_used: :system_one, confidence: 0.5, complexity: -0.5)
      expect(d.complexity).to eq(0.0)
    end

    it 'starts with nil outcome' do
      expect(decision.outcome).to be_nil
    end

    it 'defaults effort_cost to 0.0' do
      expect(decision.effort_cost).to eq(0.0)
    end

    it 'sets created_at' do
      expect(decision.created_at).to be_a(Time)
    end

    it 'accepts optional heuristic_id' do
      d = described_class.new(
        query: 'x', domain: :d, system_used: :system_one,
        confidence: 0.5, complexity: 0.2, heuristic_id: 'abc-123'
      )
      expect(d.heuristic_id).to eq('abc-123')
    end
  end

  describe '#outcome=' do
    it 'sets the outcome' do
      decision.outcome = :correct
      expect(decision.outcome).to eq(:correct)
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      result = decision.to_h
      expect(result).to include(:id, :query, :domain, :system_used, :confidence,
                                :complexity, :heuristic_id, :outcome, :effort_cost,
                                :processing_time_ms, :created_at)
    end

    it 'reflects outcome after setting it' do
      decision.outcome = :incorrect
      expect(decision.to_h[:outcome]).to eq(:incorrect)
    end
  end
end
