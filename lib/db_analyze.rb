# frozen_string_literal: true

require "db_analyze/utils"
require "db_analyze/table"
require "db_analyze/column"
require "db_analyze/index"
require "db_analyze/foreign_key"
require "db_analyze/database"
require "db_analyze/klass"
require "db_analyze/mappings"
require "db_analyze/templates"

module DbAnalyze
  mattr_accessor :logger
  # the library may be used in a Rails app or a non-Rails app
  #
  # if it is in a rails app, create a config/initializers/mls_utility.rb file
  # and set the logger to Rails.logger
  #
  # if it is not in a rails app, set the logger to a logger of your choice
  # in the code that uses the library

  def self.logger
    if @@logger.nil?
      @@logger = MlsUtility::ScriptHelpers.setup_logging(:info, false)
    end
    @@logger
  end

  def self.logger=(value)
    @@logger = value
  end
end
