# frozen_string_literal: true

module DbAnalyze
  class Column
    include MlsUtility::ModelFeatures
    include DbAnalyze::Utils

    attribute :table
    attribute :name
    attribute :type
    attribute :default
    attribute :null
    attribute :index
    attribute :primary_key
    attribute :actual_column
    attribute :created
    attribute :output


    FILTER_FIELDS = %w[name type null index default created].freeze

    def initialize(args = {}, &block)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      super(args)
      if block
        yield self
      end

      if actual_column.nil?
        raise "BOOM"
      end
      self.created = created.nil? ? false : created
      capture_actual
    end

    def extract_default(actual_column)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      unless actual_column.default.nil?
        return actual_column.default
      end
      unless actual_column.default_function.nil?
        return %(-> { #{actual_column.default_function.inspect} })
      end
      nil
    end

    # :name, :type, :options, :sql_type
    def dump(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      output.puts %(\t#{name}, type: #{actual_column.type.inspect}, sql_type: #{actual_column.sql_type.inspect}, created: #{created.inspect})
    end

    def to_h
      attributes
    end

    # emits a hash with string keys with all keys
    def unfiltered
      to_h
    end

    # emits a hash with string keys with only the keys needed for rendering
    def filtered(filter = FILTER_FIELDS, options = {})
      filtered = attributes.slice(*filter)
    end

    private

    def capture_actual
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      self.name = actual_column.name
      self.type = actual_column.type
      self.null = actual_column.null
      self.default = extract_default(actual_column)
      index = table.find_index_for_column(name)
      unless index.blank?
        index.each do |_key, value|
        # puts "index: #{value.filtered}"
        self.index = value.filtered
        # ap self.index
        end
      end
    end
  end
end
