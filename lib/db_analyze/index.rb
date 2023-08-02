# frozen_string_literal: true

module DbAnalyze
  class Index
    include MlsUtility::ModelFeatures
    include DbAnalyze::Utils

    attribute :table
    attribute :name
    attribute :unique
    attribute :index_type
    attribute :columns
    attribute :actual_index
    attribute :created
    attribute :output

    FILTER_FIELDS = %w[name unique columns index_type].freeze

    def initialize(args = {}, &block)
      super(args)
      if block
        yield self
      end

      if actual_index.nil?
        raise "BOOM"
      end
      self.created = created.nil? ? false : created
      capture_actual_index
    end

    def capture_actual_index
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      self.name = actual_index.name
      self.unique = actual_index.unique
      self.index_type = actual_index.type
      self.columns = actual_index.columns
    end
    # :table, :name, :unique, :columns, :lengths, :orders, :opclasses, :where, :type, :using, :comment
    def dump(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg

      output.puts %(\t#{name}, unique: #{actual_index.unique.inspect}, index_type: #{actual_index.type.inspect}, created: #{created.inspect})
    end

    def connection
      ActiveRecord::Base.connection
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
  end
end
