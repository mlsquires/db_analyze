# frozen_string_literal: true

require "amazing_print"
require "mls_utility"

module DbAnalyze
  class Config
    include MlsUtility::ModelFeatures

    # all directories are absolute paths
    attribute :project_root #
    attribute :output_directory

    FILENAME_MAP = {
      default_output: %(default_output.txt)
    }

    DIRECTORY_MAP = {
      tables: %(tables),
      klasses: %(klasses)
    }

    DIRECTORY_LIST = %w[output_directory].freeze

    # those directories are given as absolute paths
    def initialize(args = {})
      super
      if block_given?
        yield self
      end

      if project_root.nil?
        msg = %(#{self.class.name}.#{__method__}: project_root must be set)
        DbAnalyze.logger.fatal msg
        raise ArgumentError.new msg
      end

      self.project_root = Pathname.new(project_root)
      unless project_root.absolute?
        msg = %(#{self.class.name}.#{__method__}: project_root: #{project_root.inspect} must be an absolute path)
        DbAnalyze.logger.fatal msg
        raise ArgumentError.new msg
      end

      MlsUtility::Misc.labeled_dump("Config", to_h)
    end

    def fetch_filename_for_action(action)
      name = FILENAME_MAP[action.to_sym]
      if name.nil?
        msg = %(#{self.class.name}.#{__method__}: action: #{action.inspect}: not found)
        DbAnalyze.logger.error msg
        raise ArgumentError.new msg
      end
      normalize_filename(%(#{output_directory}/#{name}), "write")
    end

    def fetch_directory_for_group(group)
      name = DIRECTORY_MAP[group.to_sym]
      if name.nil?
        msg = %(#{self.class.name}.#{__method__}: group: #{group.inspect}: not found)
        DbAnalyze.logger.error msg
        raise ArgumentError.new msg
      end
      normalize_directory(%(#{output_directory}/#{name}), "write")
    end

    private

    def normalize_filename(filename, access_type = "read")
      fh = MlsUtility::FileHelper.new(
        logger: DbAnalyze.logger,
        paths: filename,
        base_path: project_root,
        access_type: access_type,
        form: "file"
      )
      if fh.errors.any?
        msg = %(#{self.class.name}.#{__method__}: filename: #{filename.inspect}: errors: #{fh.errors.details})
        DbAnalyze.logger.error msg
        raise ArgumentError.new msg
      end
      fh.full_paths.first
    end

    def normalize_directory(filename, access_type = "read")
      fh = MlsUtility::FileHelper.new(
        logger: DbAnalyze.logger,
        paths: filename,
        base_path: project_root,
        access_type: access_type,
        form: "file"
      )

      if fh.errors.any?
        msg = %(#{self.class.name}.#{__method__}: filename: #{filename.inspect}: errors: #{fh.errors.details})
        DbAnalyze.logger.error msg
        raise ArgumentError.new msg
      end
      fh.full_paths.first
    end
  end
end
