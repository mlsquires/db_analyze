# frozen_string_literal: true

require "db_analyze/utils"

module DbAnalyze
  class Table
    include MlsUtility::ModelFeatures
    include DbAnalyze::Utils

    attribute :name
    attribute :primary_key
    attribute :columns
    attribute :indexes
    attribute :created
    attribute :klass
    attribute :output

    FILTER_FIELDS = %w[name primary_key].freeze

    def initialize(args = {}, &block)
      super(args)
      if block
        yield self
      end

      if name.nil?
        raise "BOOM"
      end

      self.created = created.nil? ? false : created

      capture_actual
    end

    def capture_primary_key
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      self.primary_key = connection.primary_key(name)
    end

    def capture_indexes
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      actual_indexes = connection.indexes(name)
      self.indexes = {}
      actual_indexes.each do |actual_index|
        indexes[actual_index.name] = Index.new(table: self, actual_index: actual_index, output: output)
      end
    end

    def capture_columns
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      actual_columns = connection.columns(name)
      self.columns = {}
      actual_columns.each do |actual_column|
        attr = {
          table: self,
          actual_column: actual_column,
          output: output
        }
        if actual_column.name == primary_key
          attr[:primary_key] = true
        end
        columns[actual_column.name] = Column.new(attr)
      end
    end

    # add_foreign_key "b_models", "a_models", on_delete: :cascade
    def capture_foreign_keys
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      actual_foreign_keys = connection.foreign_keys(name)
      actual_foreign_keys.each do |actual_foreign_key|
        # foreign_keys[actual_foreign_key.name] = ForeignKey.new(table: self, actual_foreign_key: actual_foreign_key, output: output)
        foreign_key = ForeignKey.new(table: self, actual_foreign_key: actual_foreign_key, output: output)
        Mappings.foreign_keys[foreign_key.name] = foreign_key
      end
    end

    def add_foreign_key(to_table:)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      foreign_key = ForeignKey.create(from_table: self, to_table: to_table, output: output)
      # foreign_key.dump
    end

    def render(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      template = Templates.load_template(:create_table)
      args = {
        "klass" => self.klass.name.pluralize,
        "name" => self.name.to_sym,
        "primary_key_column" => columns[primary_key].filtered,
        "columns" => columns.reject { |key, _value| key == primary_key }.map { |_key, value| value.filtered },
        "indexes" => indexes.map { |_key, value| value.filtered },
      }
      output.puts template.render(args)
    end

    def find_index_for_column (column_name )
      mls_msg = %(#{self.class.name}.#{__method__}( #{column_name.inspect} ))
      DbAnalyze.logger.debug mls_msg
      candidates = indexes.select { |_key, index| index.columns.include?(column_name) }
      mls_msg = %(#{self.class.name}.#{__method__}: return #{candidates.length}  )
      DbAnalyze.logger.debug mls_msg
      candidates
    end

    def dump(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      output.puts %(\nTable: #{name}, created: #{created.inspect})
      dump_columns(opts)
      dump_indexes(opts)
      # dump_foreign_keys(opts)
    end

    def dump_columns(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      columns.each do |_column_name, column|
        column.dump(opts)
      end
    end

    def dump_indexes(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      indexes.each do |_index_name, index|
        index.dump(opts)
      end
    end

    def connection
      ActiveRecord::Base.connection
    end

    # emits a hash with string keys
    def to_h
      attributes
    end

    # emits a hash with string keys
    def unfiltered
      to_h
    end

    # emits a hash with keys with only the keys needed for rendering
    def filtered(filter = FILTER_FIELDS, options = {})
      filtered = attributes.slice(*filter)
    end

    private

    def capture_actual
      capture_primary_key
      capture_indexes
      capture_columns
      capture_foreign_keys
    end

  end
end
