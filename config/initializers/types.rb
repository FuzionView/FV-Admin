require "active_record/connection_adapters/postgresql_adapter"
# This application uses the PostGIS extension without the corresponding postgis
# adapter gem and therefore the "geometry" type is unknown to ActiveRecord which
# causes a warning:
#
# unknown OID: failed to recognize type of 'geometry'. It will be treated as String.
#
# The following silences this warning by explicitly aliasing "geometry" to "text".
module PostgresGeometryExtension
  def load_additional_types(oids = nil)
    type_map.alias_type "geometry", "text"
    super
  end
end
ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend PostgresGeometryExtension
