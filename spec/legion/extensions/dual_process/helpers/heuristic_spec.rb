# frozen_string_literal: true

RSpec.describe Legion::Extensions::DualProcess::Helpers::Heuristic do
  let(:heuristic) do
    described_class.new(pattern: 'greeting', domain: :social, response: :wave)
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(heuristic.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores pattern, domain, and response' do
      expect(heuristic.pattern).to eq('greeting')
      expect(heuristic.domain).to eq(:social)
      expect(heuristic.response).to eq(:wave)
    end

    it 'defaults confidence to DEFAULT_CONFIDENCE' do
      expect(heuristic.confidence).to eq(Legion::Extensions::DualProcess::Helpers::Constants::DEFAULT_CONFIDENCE)
    end

    it 'accepts custom confidence' do
      h = described_class.new(pattern: :x, domain: :d, response: :r, confidence: 0.8)
      expect(h.confidence).to eq(0.8)
    end

    it 'clamps confidence to floor' do
      h = described_class.new(pattern: :x, domain: :d, response: :r, confidence: -1.0)
      expect(h.confidence).to eq(Legion::Extensions::DualProcess::Helpers::Constants::CONFIDENCE_FLOOR)
    end

    it 'clamps confidence to ceiling' do
      h = described_class.new(pattern: :x, domain: :d, response: :r, confidence: 2.0)
      expect(h.confidence).to eq(Legion::Extensions::DualProcess::Helpers::Constants::CONFIDENCE_CEILING)
    end

    it 'starts with zero use_count and success_count' do
      expect(heuristic.use_count).to eq(0)
      expect(heuristic.success_count).to eq(0)
    end

    it 'sets created_at' do
      expect(heuristic.created_at).to be_a(Time)
    end

    it 'starts with nil last_used_at' do
      expect(heuristic.last_used_at).to be_nil
    end
  end

  describe '#use!' do
    it 'increments use_count' do
      heuristic.use!(success: true)
      expect(heuristic.use_count).to eq(1)
    end

    it 'increments success_count on success' do
      heuristic.use!(success: true)
      expect(heuristic.success_count).to eq(1)
    end

    it 'does not increment success_count on failure' do
      heuristic.use!(success: false)
      expect(heuristic.success_count).to eq(0)
    end

    it 'sets last_used_at' do
      heuristic.use!(success: true)
      expect(heuristic.last_used_at).to be_a(Time)
    end

    it 'boosts confidence on success' do
      original = heuristic.confidence
      heuristic.use!(success: true)
      expect(heuristic.confidence).to be > original
    end

    it 'reduces confidence on failure' do
      original = heuristic.confidence
      heuristic.use!(success: false)
      expect(heuristic.confidence).to be < original
    end

    it 'does not exceed CONFIDENCE_CEILING' do
      10.times { heuristic.use!(success: true) }
      expect(heuristic.confidence).to be <= Legion::Extensions::DualProcess::Helpers::Constants::CONFIDENCE_CEILING
    end

    it 'does not go below CONFIDENCE_FLOOR' do
      10.times { heuristic.use!(success: false) }
      expect(heuristic.confidence).to be >= Legion::Extensions::DualProcess::Helpers::Constants::CONFIDENCE_FLOOR
    end
  end

  describe '#success_rate' do
    it 'returns 0.0 with no uses' do
      expect(heuristic.success_rate).to eq(0.0)
    end

    it 'computes ratio correctly' do
      2.times { heuristic.use!(success: true) }
      heuristic.use!(success: false)
      expect(heuristic.success_rate).to be_within(0.001).of(2.0 / 3.0)
    end
  end

  describe '#reliable?' do
    it 'returns false with no uses' do
      expect(heuristic.reliable?).to be false
    end

    it 'returns false with fewer than 3 uses' do
      2.times { heuristic.use!(success: true) }
      expect(heuristic.reliable?).to be false
    end

    it 'returns true with high success rate and enough uses' do
      5.times { heuristic.use!(success: true) }
      expect(heuristic.reliable?).to be true
    end

    it 'returns false with low success rate even with many uses' do
      5.times { heuristic.use!(success: false) }
      expect(heuristic.reliable?).to be false
    end
  end

  describe '#to_h' do
    it 'includes all key fields' do
      result = heuristic.to_h
      expect(result).to include(:id, :pattern, :domain, :response, :confidence,
                                :use_count, :success_count, :success_rate, :reliable,
                                :created_at, :last_used_at)
    end

    it 'reflects current state' do
      heuristic.use!(success: true)
      result = heuristic.to_h
      expect(result[:use_count]).to eq(1)
      expect(result[:success_count]).to eq(1)
    end
  end
end
