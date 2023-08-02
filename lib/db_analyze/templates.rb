# frozen_string_literal: true

require "liquid"

module DbAnalyze
  module Templates

    Liquid::Template.error_mode = :strict

    @@available_templates = {
      create_table: "create_table.liquid",
      create_klass: "create_klass.liquid",
    }

    @@templates = {}

    def self.available_templates
      @@available_templates
    end

    def self.templates
      @@templates
    end

    def self.load_template(name)
      @@templates[name] ||= self.load_template_file(name)
    end

    def self.load_template_file(name)
      template_file = File.join(File.dirname(__FILE__), "templates", @@available_templates[name])
      raw = File.read(template_file)
      Liquid::Template.parse(raw, error_mode: :strict)
    end

  end
end
