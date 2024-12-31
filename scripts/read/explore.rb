#!/usr/bin/env ruby

# frozen_string_literal: true

load %(#{ENV["HOME"]}/MLS_UTILITY_PROJECT_ROOT_FILENAME.TXT)

project_root = determine_project_root

set_load_paths(project_root, %w[./lib ./scripts/common])

require "dotenv/load"
require "bundler/setup"
require "amazing_print"
require "mls_utility"
require "db_analyze"
require "script_common"

# require "domain_library" as needed

# This class only has code that is specific to this script.
# The common code is in the BaseRunner class.
class Runner < MlsUtility::BaseRunner
  include ScriptCommon
  # script specific code

  ARGS_NEEDED = %i[verbose debug output_directory reports details].freeze
  ARGS_REQUIRED = %i[output_directory].freeze
  REPORT_CANDIDATES = %w[create_table create_klass create_foreign_key create_plantuml].freeze
  DETAIL_CANDIDATES = %w[each_file].freeze

  # <editor-fold desc="Do The Work" note="">
  # script specific processing

  def do_the_work
    msg = %(#{self.class.name}.#{__method__}: ENTERED)
    @logger.info msg

    establish_application_base

    database = DbAnalyze::Database.new(service: @service)
    database.render
  end

  # </editor-fold>

  # <editor-fold desc="Arguments and Options" note="">

  # You will need to customize these methods for each script, although they will be similar
  # for most scripts
  # script specific validation
  def valid_options?
    ok = common_validations
    return false unless ok

    @output_directory = MlsUtility::ScriptHelpers.validate_directory(@project_root, @option_manager
                                                                                      .current_options[:output_directory], "file", "write", true)
    if @output_directory.nil?
      msg = %(#{self.class.name}.#{__method__}: @output_directory: #{@output_direcotory.inspect} is not valid)
      @logger.error msg
      return false
    end
    @debug = @option_manager.current_options[:debug]
    @verbose = @option_manager.current_options[:verbose]

    reports = extract_and_validate_list("reports", @option_manager.current_options[:reports], report_candidates)
    return false if reports.nil?
    @reports = reports

    details = extract_and_validate_list("details", @option_manager.current_options[:details], detail_candidates)
    return false if details.nil?
    @details = details

    true
  end

  # script specific defaults

  def set_default_options
    options = HashWithIndifferentAccess.new
    options[:verbose] = false
    options[:debug] = false
    @option_manager.merge_options("set_default_options", options)
  end

  # script specific methods
  def args_needed
    ARGS_NEEDED
  end

  def args_required
    ARGS_REQUIRED
  end

  def detail_candidates
    DETAIL_CANDIDATES
  end

  def report_candidates
    REPORT_CANDIDATES
  end

  def determine_option_filename
    MlsUtility::ScriptHelpers.determine_option_filename(__FILE__)
  end

  # how should this script be executed? pick one or define a new one
  def executable_prefix
    %(bundle exec rails runner)
  end

  # </editor-fold>
end

logger = MlsUtility::ScriptHelpers.setup_logging(:info, true)
MlsUtility.logger = logger
MlsUtility.labeled_dump_detail = true
MlsUtility.labeled_dump_enable = true
DbAnalyze.logger = logger

runner = Runner.new(project_root, logger)
options = runner.get_cli_options(ARGV)
runner.perform(options)
