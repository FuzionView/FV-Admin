require 'uri'
class Dataset < ApplicationRecord
  belongs_to :owner
  validates :name, :source_dataset, :source_sql, presence: true


  # def self.source(test='esri'))
  #   esri = 'https://pca-gis02.pca.state.mn.us/arcgis/rest/services/agol/remediation_ic/MapServer/2/query?f=json&where=1%3D1&outFields=*&orderByFields=OBJECTID&resultRecordCount=1'
  #   wfs  = 'https://pwgeo.org/datasets/PUBLIC/GEODETIC_CONTROL_POINTS/STP_MONUMENTS/monuments_2015_public.map?'
  #   uri = if test == 'esri'
  #           esri
  #         else
  #           efs
  #         end

  #   u = URI(uri)


  #   if u.path.include?('arcgis')
  #     # esri/json
  #     response = HTTParty.get(uri)
  #     puts response.dig('spatialReference', 'latestWkid') #SRS
  #   else
  #     # wfs/xml
  #     response.headers.inspect

  #   end
  # end
end
