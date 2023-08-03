#!/usr/bin/env ruby

# frozen_string_literal: true

load "MLS_UTILITY_PROJECT_ROOT_FILENAME.TXT"

project_root = determine_project_root

set_load_paths(project_root, ["./lib"])

require "dotenv/load"
require "bundler/setup"
require "amazing_print"
require "mls_utility"
require "db_analyze"

module Runner
  include DbAnalyze::Utils

  logger = MlsUtility::ScriptHelpers.setup_logging(:info, true)
  MlsUtility.logger = logger
  DbAnalyze.logger = logger

  output = $stdout
  opts = {
    write_tables: "./output/tables",
    write_klasses: "./output/klasses",
  }
  database = DbAnalyze::Database.new(output: output, opts: opts)
  database.render

end
