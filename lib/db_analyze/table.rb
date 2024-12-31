# frozen_string_literal: true

require "db_analyze/utils"
require "fileutils"

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
    attribute :service

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
      self.indexes = {}
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
      self.indexes   = {}
      actual_indexes.each do | actual_index |
        indexes[actual_index.name] = Index.new(table: self, actual_index: actual_index, service: service)
      end
    end

    def capture_columns
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      actual_columns = connection.columns(name)
      self.columns   = {}
      actual_columns.each do | actual_column |
        attr                        = {
          table:         self,
          actual_column: actual_column,
          service:       service
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
      actual_foreign_keys.each do | actual_foreign_key |
        # foreign_keys[actual_foreign_key.name] = ForeignKey.new(table: self, actual_foreign_key: actual_foreign_key, service: service)
        foreign_key                             = ForeignKey.new(table: self, actual_foreign_key: actual_foreign_key, service: service)
        Mappings.foreign_keys[foreign_key.name] = foreign_key
      end
    end

    def add_foreign_key(to_table:)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      foreign_key = ForeignKey.create(from_table: self, to_table: to_table, service: service)
      # foreign_key.dump
    end

    def render_table(service)
      msg = %(#{self.class.name}.#{__method__}: name: #{name.inspect})
      DbAnalyze.logger.debug msg
      template = Templates.load_template(:create_table)
      if primary_key.nil?
        primary_key_column = nil
      else
        if primary_key.is_a?(Array)
          puts "primary_key is an array"
        else
          primary_key_column = columns[primary_key].filtered
        end
      end
      args     = {
        "klass"              => klass.name.pluralize,
        "name"               => name,
        "primary_key_column" => primary_key_column,
        "columns"            => columns.reject { | key, _value | key == primary_key }.map { | _key, value | value.filtered },
        "indexes"            => indexes.map { | _key, value | value.filtered },
        "each_file"          => service.details.include?("each_file")
      }
      MlsUtility::Misc.labeled_dump("args", args)

      if service.details.include?("each_file")
        output_directory = service.config.fetch_directory_for_group(:tables)
        FileUtils.mkdir_p(output_directory)
      end

      if service.details.include?("each_file")
        file = create_table_file(output_directory)
        file.puts template.render(args)
        file.close
      else
        service.default_output.puts template.render(args)
      end
    end

    def render_plantuml(service)
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      template = Templates.load_template(:create_plantuml)
      args     = {
        "klass"              => klass.name,
        "name"               => klass.name.singularize.underscore,
        "primary_key_column" => columns[primary_key].filtered,
        "columns"            => columns.reject { | key, _value | key == primary_key }.map { | _key, value | value.filtered },
        "indexes"            => indexes.map { | _key, value | value.filtered }
      }

      if service.details.include?("each_file")
        output_directory = service.config.fetch_directory_for_group(:tables)
        FileUtils.mkdir_p(output_directory)
      end

      if service.details.include?("each_file")
        file = create_plantuml_file(output_directory)
        file.puts template.render(args)
        file.close
      else
        service.default_output.puts template.render(args)
      end
    end

    def create_table_file(output_directory)
      basename      = Pathname.new(%(#{name}.rb))
      full_pathname = output_directory + basename
      puts %(Writing file: #{basename})
      file = File.open(full_pathname.to_s, "w")
    end

    def create_plantuml_file(output_directory)
      basename      = Pathname.new(%(#{klass.name.singularize.underscore}.iuml))
      full_pathname = output_directory + basename
      puts %(Writing file: #{basename})
      file = File.open(full_pathname.to_s, "w")
    end

    def find_index_for_column(column_name)
      mls_msg = %(#{self.class.name}.#{__method__}( #{column_name.inspect} ))
      DbAnalyze.logger.debug mls_msg
      candidates = indexes.select { | _key, index | index.columns.include?(column_name) }
      mls_msg    = %(#{self.class.name}.#{__method__}: return #{candidates.length}  )
      DbAnalyze.logger.debug mls_msg
      candidates
    end

    def dump
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      output.puts %(\nTable: #{name}, created: #{created.inspect})
      dump_columns
      dump_indexes
      # dump_foreign_keys(opts)
    end

    def dump_columns
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      columns.each do | _column_name, column |
        column.dump(service)
      end
    end

    def dump_indexes
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      indexes.each do | _index_name, index |
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
