# frozen_string_literal: true

require "db_analyze/utils"

module DbAnalyze
  class Klass
    include MlsUtility::ModelFeatures
    include DbAnalyze::Utils

    attribute :name
    attribute :superclass
    attribute :actual_klass
    attribute :reflections
    attribute :created
    attribute :primary_key
    attribute :table
    attribute :table_name
    attribute :output
    attribute :opts

    FILTER_FIELDS = %w[name created primary_key].freeze
    INTERESTING_FIELDS = {
      name: false,
      table_name: false,
      primary_key: false,
      columns_hash: true,
      attribute_names: false,
      attribute_types: false,
      column_defaults: true,
      column_names: false,
      columns: false,
      content_columns: false,
      filter_attributes: false,
      generated_association_methods: false,
      ignored_columns: false,
      inspection_filter: false,
      readonly_attributes: false,
      reflect_on_all_aggregations: false,
      reflect_on_all_autosave_associations: false,
      reflections: true,
      stored_attributes: false
    }.freeze
    # INDEX_FIELDS = %i[table name unique columns].freeze
    # FOREIGN_KEY_FIELDS = %i[from_table to_table column primary_key on_delete on_update].freeze

    def initialize(args = {}, &block)
      super(args)
      if block
        yield self
      end

      if table.nil?
        raise "BOOM"
      end

      self.opts = opts.nil? ? {} : opts
      refresh_klass
    end

    def create_ar_model(table_name)
      superclass = determine_klass_superclass
      klass = Class.new(superclass)
      Object.const_set(name, klass)
    end

    def render(opts = {})
      mls_msg = %(#{self.class.name}.#{__method__}: enter )
      DbAnalyze.logger.debug mls_msg
      template = Templates.load_template(:create_klass)
      args = {
        "name" => self.name,
        "superclass" => self.superclass,
        "reflections" => reflection_objects,
      }
      if opts[:write_klasses]
        file = create_file
        file.puts template.render(args)
        file.close
      else
        output.puts template.render(args)
      end

    end

    def create_file
      filename = %(#{opts[:write_klasses]}/create_klass_#{name}.rb)
      puts %(Writing file: #{filename})
      file = File.open(filename, "w")
    end

    def dump(opts = {})
      output.puts %(\nKlass: #{name}, table_name: #{table.name}, created: #{created.inspect})
    end

    def raw_dump

      INTERESTING_FIELDS.each do |key, try|
        output.puts %(#{key}: #{actual_klass.send(key).inspect}) if try
      end


    end

    def dump_reflections
      reflections.each do |key, value|
        output.puts %(#{key}: #{value.class.name} #{value.name} #{value.macro})
      end
    end

    def reflection_objects
      reflections.map do |key, value|
        { "macro" => value.macro, "name" => value.name }
      end
    end

    def add_has_many(other_klass)
      actual_klass.has_many other_klass.name.underscore.pluralize.to_sym
    end

    def connection
      ActiveRecord::Base.connection
    end

    def to_h
      attributes
    end

    # TODO: (michael, 2023-07-18): maybe alias this to to_h
    # emits a hash with string keys with all keys
    def unfiltered
      to_h
    end

    # emits a hash with string keys with only the keys needed for rendering
    def filtered(filter = FILTER_FIELDS, options = {})
      filtered = attributes.slice(*filter)
      filtered["table_name"] = table.name
    end


    def refresh_klass
      capture_klass
      update_mappings
      dump_reflections
    end

    def update_mappings
      klass = self
      Mappings.klasses[klass.name] = klass
      # link the table back to this klass
      klass.table.klass = klass
      Mappings.klasses_to_tables[klass.name] = table.name
      Mappings.tables_to_klasses[table.name] = klass.name
    end

    def capture_klass
      # puts %(#{self.class.name}.#{__method__}: enter)
      table_name = table.name
      self.name = determine_klass_name(table_name)
      if class_exists?(name)
        self.actual_klass = Object.const_get(name)
        self.created = false
      else
        self.actual_klass = create_ar_model(table_name)
        self.created = true
      end
      self.actual_klass.table_name = table_name
      self.table_name = table.name
      self.primary_key = table.primary_key
      self.superclass = actual_klass.superclass.name
      self.reflections = actual_klass.reflections
    end
  end
end
