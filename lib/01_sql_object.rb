require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    rows = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    rows[0].map(&:to_sym)
  end

  def self.finalize!
    columns.each do |column_name|
      define_method(column_name) do
        attributes[column_name]
      end
      setter_name = "#{column_name}="
      define_method(setter_name) do |value|
        attributes[column_name] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    all = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    self.parse_all(all)
  end

  def self.parse_all(results)
    array_of_obj = []
    results.each do |hash|
      array_of_obj << self.new(hash)
    end
    array_of_obj
  end

  def self.find(id)
    arr = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    return nil if arr.empty?
    self.new(arr.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      setter_name = "#{attr_name}=".to_sym
      self.send(setter_name, value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    columns_no_id = self.class.columns.drop(1)
    col_names = columns_no_id.join(", ")
    num_cols = columns_no_id.length
    question_marks = (["?"] * num_cols).join(", ")
    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns_no_id = self.class.columns.drop(1)
    set_line = columns_no_id
      .map { |column| "#{column} = ?" }
      .join(", ")

    pass_in_values = attribute_values.drop(1)
      .concat([self.id])

    DBConnection.execute(<<-SQL, *pass_in_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    if self.id.nil?
      insert
    else
      update
    end
  end
end
