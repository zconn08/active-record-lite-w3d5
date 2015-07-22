require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    default = options
    @name = name

    if default[:foreign_key].nil?
      @foreign_key = ("#{@name}_id").to_sym
    else
      @foreign_key = default[:foreign_key]
    end

    if default[:class_name].nil?
      @class_name = @name.to_s.camelcase
    else
      @class_name = default[:class_name]
    end

    if default[:primary_key].nil?
      @primary_key = :id
    else
      @primary_key = default[:primary_key]
    end

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    default = options
    @name = name

    if default[:foreign_key].nil?
      @foreign_key = ("#{self_class_name.underscore}_id").to_sym
    else
      @foreign_key = default[:foreign_key]
    end

    if default[:class_name].nil?
      @class_name = @name.to_s.singularize.camelcase
    else
      @class_name = default[:class_name]
    end

    if default[:primary_key].nil?
      @primary_key = :id
    else
      @primary_key = default[:primary_key]
    end

  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    self.assoc_options[name] = BelongsToOptions.new(name, options)

    define_method(name) do
      ops = self.class.assoc_options[name]
      primary_key_col = ops.primary_key
      foreign_key_val = self.send(ops.foreign_key)

      ops
        .model_class
        .where(primary_key_col => foreign_key_val)
        .first
    end
  end

  def has_many(name, options = {})
    self.assoc_options[name] = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      ops = self.class.assoc_options[name]
      primary_key_val = self.send(ops.primary_key)
      foreign_key_col = ops.foreign_key

      ops
        .model_class
        .where(foreign_key_col => primary_key_val)
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
