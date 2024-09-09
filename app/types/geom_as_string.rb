# app/types/geom_as_string.rb
class GeomAsString < ActiveRecord::Type::Value

  # Cast value before it's stored in the database
  def serialize(value)
    return if value.nil?
    result = ActiveRecord::Base.connection.select_value(
      "SELECT st_multi(st_transform(st_geomfromgeojson(#{ActiveRecord::Base.connection.quote(value)}), 6344))"
    )
    result
  end

  # Cast value when it's loaded from the database
  def deserialize(value)
    return if value.nil?
    result = ActiveRecord::Base.connection.select_value(
      "SELECT st_asgeojson(st_transform(#{ActiveRecord::Base.connection.quote(value)}, 4326))"
    )
    result
  end

  def cast(value)
    value.to_s
  end
end
