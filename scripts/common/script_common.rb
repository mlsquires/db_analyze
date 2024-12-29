# frozen_string_literal: true

# This module is for code that is common to all scripts within a domain.
# Suggest that you create a "scripts/common" directory and place this file in it.
module ScriptCommon
  # Extracts a list from a string or array and validates that all entries are in the candidate list
  # all keys are converted to strings
  def extract_and_validate_list(label, list, candidates)
    msg = %(#{self.class.name}.#{__method__}( #{label.inspect}, #{list.inspect}, #{candidates.inspect} ))
    @logger.debug msg

    if list.blank?
      msg = %(#{self.class.name}.#{__method__}: #{label.inspect}: list is blank)
      @logger.warn msg
      return Set.new
    end

    if list.is_a?(String)
      list = list.split(",").map(&:strip)
    end

    list_str = list.map(&:to_s)
    candidates_str = candidates.map(&:to_s)
    candidate_set = Set.new(candidates_str)
    list_set = Set.new(list_str)
    extra = list_set - candidate_set
    if extra.empty?
      return list_set
    end
    msg = %(#{self.class.name}.#{__method__}: #{label.inspect}: non-matching entries #{extra.to_a.inspect}  )
    @logger.error msg
    nil
  end

  def establish_application_base
    @config = DbAnalyze::Config.new(project_root: @project_root, output_directory: @output_directory)
    default_output_name = @config.fetch_filename_for_action(:default_output)
    @default_output = File.open(default_output_name, "w")
    @service = DbAnalyze::Service.new(config: @config, logger: @logger, option_manager: @option_manager, reports:
      @reports, details: @details, default_output: @default_output)
  end
end
