module ScriptCommon
  def self.setup_logging(level = :debug, include_active_record = true)
    $stdout.sync = true

    base_logger = ActiveSupport::Logger.new($stdout)
    base_logger.formatter = ::Logger::Formatter.new
    logger = ActiveSupport::TaggedLogging.new(base_logger)

    if defined?(Rails)
      Rails.logger = logger
      if include_active_record
        ActiveRecord::Base.logger = logger
      end
    end

    base_logger.level = level || :debug
    logger
  end
end
