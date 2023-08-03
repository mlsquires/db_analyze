# frozen_string_literal: true

# module ActiveRecord
#   class Base
class ApplicationRecord
  def self.descendants
    ObjectSpace.each_object(Class).select do |klass|
      subclass = klass < self
      if subclass.nil?
        false
      else
        # puts %(klass: #{klass}, self: #{self}, subclass: #{subclass.inspect})
        subclass
      end
    end
  end
end

# end

module DbAnalyze
  module Utils
    def determine_klass_name(table_name)
      table_name.classify
    end

    def class_exists?(class_name)
      klass = Module.const_get(class_name)
      klass.is_a?(Class)
    rescue NameError
      false
    end

    # finds all concrete ActiveRecord::Base descendants
    # ONLY after all models have been loaded
    def find_ar_klasses
      klasses = ActiveRecord::Base.descendants
      concrete = klasses.select { |klass| !klass.abstract_class? }
      sortable = concrete.map { |klass| [klass, klass.name] }
      sorted = sortable.sort_by { |a| a[1] }
      sorted.map { |klass| klass[0] }
    end

    def determine_klass_superclass
      candidates = %w[ActiveRecord::Base]
      candidates.each do |candidate|
        if class_exists?(candidate)
          return Module.const_get(candidate)
        end
      end
      raise "BOOM"
    end

    def render_name( name, form = :symbol)
      case form
      when :symbol
        name.to_sym.inspect
      when :string
        name.to_s.inspect
      else
        raise "BOOM"
      end
    end

  end
end
