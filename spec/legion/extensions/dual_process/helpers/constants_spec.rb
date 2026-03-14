# frozen_string_literal: true

RSpec.describe Legion::Extensions::DualProcess::Helpers::Constants do
  it 'defines MAX_DECISIONS' do
    expect(described_class::MAX_DECISIONS).to eq(200)
  end

  it 'defines MAX_HEURISTICS' do
    expect(described_class::MAX_HEURISTICS).to eq(100)
  end

  it 'defines MAX_HISTORY' do
    expect(described_class::MAX_HISTORY).to eq(300)
  end

  it 'defines confidence bounds' do
    expect(described_class::CONFIDENCE_FLOOR).to eq(0.05)
    expect(described_class::CONFIDENCE_CEILING).to eq(0.95)
    expect(described_class::DEFAULT_CONFIDENCE).to eq(0.5)
  end

  it 'defines routing thresholds' do
    expect(described_class::SYSTEM_ONE_THRESHOLD).to eq(0.6)
    expect(described_class::COMPLEXITY_THRESHOLD).to eq(0.5)
  end

  it 'defines effort constants' do
    expect(described_class::EFFORT_COST).to eq(0.1)
    expect(described_class::EFFORT_RECOVERY_RATE).to eq(0.05)
    expect(described_class::MAX_EFFORT_BUDGET).to eq(1.0)
    expect(described_class::FATIGUE_PENALTY).to eq(0.15)
    expect(described_class::HEURISTIC_BOOST).to eq(0.2)
    expect(described_class::DECAY_RATE).to eq(0.01)
  end

  it 'defines SYSTEMS' do
    expect(described_class::SYSTEMS).to contain_exactly(:system_one, :system_two)
  end

  it 'defines ROUTING_LABELS as a hash of ranges' do
    labels = described_class::ROUTING_LABELS.values
    expect(labels).to include(:automatic, :fluent, :effortful, :strained, :depleted)
  end

  it 'covers the full 0..1 range in ROUTING_LABELS' do
    labels = described_class::ROUTING_LABELS
    expect(labels.any? { |range, _| range.cover?(0.0) }).to be true
    expect(labels.any? { |range, _| range.cover?(1.0) }).to be true
    expect(labels.any? { |range, _| range.cover?(0.5) }).to be true
  end

  it 'defines DECISION_OUTCOMES' do
    expect(described_class::DECISION_OUTCOMES).to contain_exactly(:correct, :incorrect, :uncertain)
  end
end
