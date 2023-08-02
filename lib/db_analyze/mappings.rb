# frozen_string_literal: true

module DbAnalyze
  module Mappings
    # name -> App
    def self.tables
      @@tables ||= {}
    end

    def self.klasses
      @@klasses ||= {}
    end

    # name -> name
    def self.tables_to_klasses
      @@tables_to_klasses ||= {}
    end

    def self.klasses_to_tables
      @@klasses_to_tables ||= {}
    end

    def self.foreign_keys
      @@foreign_keys ||= {}
    end

  end
end
