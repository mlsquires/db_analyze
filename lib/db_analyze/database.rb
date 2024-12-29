# frozen_string_literal: true

require "dotenv/load"
require "active_record"

module DbAnalyze
  class Database
    include MlsUtility::ModelFeatures

    SCHEMA_NAMES = %w[public].freeze
    FILTER_FIELDS = %w[name].freeze
    IGNORE_TABLES = %w[schema_migrations ar_internal_metadata].freeze

    attribute :db_config
    attribute :database_name
    attribute :service

    def initialize(args = {})
      super(args)
      if block_given?
        yield self
      end

      establish_connection
      self.db_config = ::ActiveRecord::Base.connection_db_config
      self.database_name = db_config.database
      capture_tables
      create_klasses
      # create_sample_has_many
      # create_sample_foreign_key
      # klass = Mappings.klasses["BModel"]
      # klass.raw_dump
    end

    def establish_connection
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg

      config = {
        adapter: ENV["DB_ADAPTER"] || "postgresql",
        host: ENV["DB_HOST"] || "localhost",
        port: ENV["DB_PORT"] || "5432",
        username: ENV["DB_USER_NAME"] || "BogusUser",
        password: ENV["DB_PASSWORD"] || "BogusPassword",
        database: ENV["DB_DATABASE_NAME"] || "BogusDatabase"
      }
      ActiveRecord::Base.establish_connection(config)
    end

    def connection
      ActiveRecord::Base.connection
    end

    def create_sample_foreign_key
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      # klasses["BModel"].table.add_foreign_key("a_models", on_delete: :cascade)
      from_table = Mappings.tables["b_models"]
      to_table = Mappings.tables["a_models"]
      from_table.add_foreign_key(to_table: to_table)
    end

    def create_sample_has_many
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      from_klass = Mappings.klasses["AModel"]
      to_klass = Mappings.klasses["BModel"]
      from_klass.add_has_many(to_klass)
      from_klass.refresh_klass
    end

    def capture_tables
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      table_names = connection.tables.reject { |t| IGNORE_TABLES.include?(t) }.sort
      table_names.each do |table_name|
        Mappings.tables[table_name] = Table.new(name: table_name, service: service)
      end
    end

    def create_klasses
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      Mappings.tables.each do |_table_name, table|
        DbAnalyze::Klass.new(table: table, service: service)
      end
    end

    def dump
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      Mappings.klasses.each do |_klass_name, klass|
        klass.dump(service)
      end
      Mappings.tables.each do |_table_name, table|
        table.dump(service)
      end
    end

    def render
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg

      if service.reports.include?("create_table")
        Mappings.tables.each do |_table_name, table|
          table.render_table(service)
        end
      end

      if service.reports.include?("create_plantuml")
        Mappings.tables.each do |_table_name, table|
          table.render_plantuml(service)
        end
      end

      if service.reports.include?("create_foreign_key")
        Mappings.foreign_keys.each do |_foreign_key_name, foreign_key|
          foreign_key.render(service)
        end
      end

      if service.reports.include?("create_klass")
        Mappings.klasses.each do |_klass_name, klass|
          klass.render(service)
        end
      end
    end

    def to_h
      attributes.with_indifferent_access
    end

    # TODO: (michael, 2023-07-18): maybe alias this to to_h
    # emits a hash with string keys with all keys
    def unfiltered
      to_h
    end

    # emits a hash with string keys with only the keys needed for rendering
    def filtered(filter = FILTER_FIELDS, options = {})
      ret = attributes.slice(*filter)
      klasses_attributes = []
      klasses.each do |_klass_name, klass|
        klasses_attributes << klass.filtered
      end
      ret[:klasses] = klasses_attributes
      ret
    end
  end
end
