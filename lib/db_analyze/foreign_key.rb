# frozen_string_literal: true

module DbAnalyze
  class ForeignKey
    include MlsUtility::ModelFeatures
    include DbAnalyze::Utils

    attribute :table
    attribute :to_table
    attribute :name
    attribute :column
    attribute :primary_key
    attribute :actual_foreign_key
    attribute :created
    attribute :output

    def initialize(args = {}, &block)
      super(args)
      if block
        yield self
      end

      if actual_foreign_key.nil?
        raise "BOOM"
      end

      self.created = created.nil? ? false : created
      capture_options
    end

    def capture_options
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      self.column = actual_foreign_key.options[:column]
      self.primary_key = actual_foreign_key.options[:primary_key]
      self.name = actual_foreign_key.options[:name]

      to_table_name = actual_foreign_key.to_table
      self.to_table = Mappings.tables[to_table_name]
    end

    # def self.create(from_table:, to_table:, foreign_key_name: nil, column:, primary_key: , on_delete: nil, on_update: nil, deferable: nil, validate: nil, output:)
    def self.create(from_table:, to_table:, output:)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      fk_name = "FOREIGN_KEY"
      actual_foreign_key = create_actual_foreign_key(from_table: from_table, to_table: to_table, foreign_key_name: fk_name, output: output)
      fk = new(table: from_table, actual_foreign_key: actual_foreign_key, output: output)

    end

    def self.create_actual_foreign_key(from_table:, to_table:, foreign_key_name:, output:)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      from_table_name = from_table.name
      to_table_name = to_table.name
      options = {
        from_table: from_table_name,
        to_table: to_table_name,
        name: foreign_key_name,
        column: "a_model_id",
        primary_key: "id",
        on_delete: :cascade,
        on_update: :cascade,
        deferable: nil,
        validate: nil
      }
      actual_foreign_key = connection.add_foreign_key(from_table_name, to_table_name, **options)
    end

    def dump(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      output.puts %(\t#{name}, from_table: #{table.name.inspect}, to_table: #{to_table.name.inspect}, column: #{column.inspect}, primary_key: #{primary_key.inspect}, created: #{created.inspect})
    end

    def self.connection
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
    def filtered(options = {})
      filtered = attributes.dup
      filtered[:to_table] = to_table.name
      filtered[:from_table] = table.name
    end
  end
end
