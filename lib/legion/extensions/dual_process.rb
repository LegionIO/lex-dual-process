# frozen_string_literal: true

require 'legion/extensions/dual_process/version'
require 'legion/extensions/dual_process/helpers/constants'
require 'legion/extensions/dual_process/helpers/heuristic'
require 'legion/extensions/dual_process/helpers/decision'
require 'legion/extensions/dual_process/helpers/dual_process_engine'
require 'legion/extensions/dual_process/runners/dual_process'

module Legion
  module Extensions
    module DualProcess
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
