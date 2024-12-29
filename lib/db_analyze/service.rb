# frozen_string_literal: true

require "amazing_print"
require "mls_utility"

# This is just a databag class to hold the various services
# that are used in the library.
# Effectively it is a global variable that is passed around.
# this probably could just be a Struct or made a singleton
module DbAnalyze
  class Service
    include MlsUtility::ModelFeatures

    attribute :config
    attribute :option_manager
    attribute :logger
    attribute :reports
    attribute :details
    attribute :default_output

    def initialize(args = {})
      super
      if block_given?
        yield self
      end
    end
  end
end
