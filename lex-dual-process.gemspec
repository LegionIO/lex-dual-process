# frozen_string_literal: true

require_relative 'lib/legion/extensions/dual_process/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-dual-process'
  spec.version       = Legion::Extensions::DualProcess::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Dual Process'
  spec.description   = "Kahneman's Dual Process Theory for brain-modeled agentic AI: System 1 (fast/intuitive) vs System 2 (slow/deliberate)"
  spec.homepage      = 'https://github.com/LegionIO/lex-dual-process'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-dual-process'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-dual-process'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-dual-process'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-dual-process/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-dual-process.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
