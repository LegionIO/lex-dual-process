# frozen_string_literal: true

require 'legion/extensions/dual_process/client'

RSpec.describe Legion::Extensions::DualProcess::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:register_heuristic)
    expect(client).to respond_to(:route_decision)
    expect(client).to respond_to(:execute_system_one)
    expect(client).to respond_to(:execute_system_two)
    expect(client).to respond_to(:record_decision_outcome)
    expect(client).to respond_to(:effort_assessment)
    expect(client).to respond_to(:best_heuristics)
    expect(client).to respond_to(:system_usage_stats)
    expect(client).to respond_to(:update_dual_process)
    expect(client).to respond_to(:dual_process_stats)
  end

  it 'accepts an injected engine' do
    custom_engine = Legion::Extensions::DualProcess::Helpers::DualProcessEngine.new
    c = described_class.new(engine: custom_engine)
    expect(c.send(:engine)).to be(custom_engine)
  end

  it 'creates its own engine when none injected' do
    expect(client.send(:engine)).to be_a(Legion::Extensions::DualProcess::Helpers::DualProcessEngine)
  end

  it 'runs a full System 1 decision cycle' do
    client.register_heuristic(pattern: 'greet', domain: :social, response: :smile, confidence: 0.9)
    route = client.route_decision(query: 'greet friend', domain: :social, complexity: 0.2)
    expect(route[:system]).to eq(:system_one)

    exec = client.execute_system_one(query: 'greet friend', domain: :social)
    expect(exec[:success]).to be true
    expect(exec[:response]).to eq(:smile)

    outcome = client.record_decision_outcome(decision_id: exec[:decision_id], outcome: :correct)
    expect(outcome[:success]).to be true

    stats = client.dual_process_stats
    expect(stats[:system_stats][:system_one]).to eq(1)
  end

  it 'runs a full System 2 decision cycle' do
    route = client.route_decision(query: 'novel complex problem', domain: :analysis, complexity: 0.9)
    expect(route[:system]).to eq(:system_two)

    exec = client.execute_system_two(
      query: 'novel complex problem', domain: :analysis,
      deliberation: { confidence: 0.88, response: :thorough_analysis }
    )
    expect(exec[:success]).to be true
    expect(exec[:response]).to eq(:thorough_analysis)

    stats = client.dual_process_stats
    expect(stats[:system_stats][:system_two]).to eq(1)
  end

  it 'tracks effort depletion and recovery' do
    initial = client.effort_assessment[:effort_level]
    expect(initial).to eq(1.0)

    5.times { client.execute_system_two(query: 'x', domain: :d) }
    after_work = client.effort_assessment[:effort_level]
    expect(after_work).to be < initial

    client.update_dual_process
    after_recovery = client.effort_assessment[:effort_level]
    expect(after_recovery).to be > after_work
  end
end
