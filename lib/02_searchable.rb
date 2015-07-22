require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params
      .keys
      .map { |attr_name| "#{attr_name} = ?" }
      .join(" AND ")
    pass_in_values = params.values
    result = DBConnection.execute(<<-SQL, *pass_in_values)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL
    self.parse_all(result)
  end
end

class SQLObject
  extend Searchable
end
