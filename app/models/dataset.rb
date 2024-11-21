require 'httparty'

class Dataset < ApplicationRecord
  WFS_XPATH_GEOM = "//xsd:complexType//xsd:element[@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType']/@name"
  ESRI_WFS_XPATH_GEOM = "//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType']/@name"
  WFS_XPATH_FEATURES = "//xsd:complexType//xsd:element[@name and not(@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType')]/@name"
  ESRI_WFS_XPATH_FEATURES = "//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@name and not(@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType')]/@name"

  belongs_to :owner
  has_many :test_tickets, ->{ order(publish_date: :desc) }, class_name: 'Ticket', dependent: :destroy
  has_many :ticket_dataset_statuses, through: :test_tickets, dependent: :destroy

  attribute :layers, default: []
  attribute :layer, default: {}

  validates :name, :source_dataset, :source_sql, presence: true

  attr_accessor :geometry_name, :layer_name, :feature_class,
                :status_id, :size, :depth, :accuracy_value,
                :description, :source_error,
                :source_co_v

  validates :geometry_name, :layer_name, :feature_class,
            :status_id, presence: true, on: :create

  before_validation :set_sql_from_template, on: :create
  before_validation :set_source_co, on: :update

  def set_source_co
    return if source_co_v.blank?

    self.source_co = source_co_v.split(',')
  end

  def set_sql_from_template
    sql_template = <<-END_SQL
    SELECT
       id,
       "#{geometry_name}" geom,
       #{sqlquote(:feature_class)},
       #{sqlquote(:status_id)},
       #{sqlquote(:size)},
       #{sqlquote(:depth)},
       #{sqlquote(:accuracy_value)},
       #{sqlquote(:description)}
     FROM
       "#{layer_name}"
     ;
          END_SQL
    self.source_sql = sql_template
  end

  def sqlquote(val)
    result = eval(val.to_s)
    if result.blank?
      "'' #{val.to_s}"
    else
      "\"#{eval(val.to_s)}\" #{val.to_s}"
    end
  end

  def get_metadata
    if source_dataset.starts_with?('http') && source_dataset&.downcase.include?('featureserver')
      return get_metadata_esri
    elsif source_dataset.starts_with?('WFS:')
      return get_metadata_wfs_xml
    elsif source_dataset.starts_with?('./')
      self.source_srs = 'EPSG:6344'
      self.layer_name = 'unknown'
      self.feature_class = 'unknown'
      self.status_id = 'unknown'
      self.geometry_name = 'geometry'
      return [['unknown'], ['geometry'], ['unknown']]
    end

    raise "Valid sources start with 'WFS:', or 'http(s)'."
  end

  def get_metadata_wfs_xml
    url = source_dataset.sub('WFS:', '').sub('?', '')
    cap_url = URI("#{url}?service=WFS&request=GetCapabilities")
    cap_request = get_request(cap_url, 3)
    cap_xml = cap_request.body
    cap_doc = Nokogiri::XML(cap_xml)
    feature_types = cap_doc.xpath('//wfs:FeatureType/wfs:Name').map(&:text)
    if feature_types.size == 1
      self.layer_name = feature_types.first
    end

    if layer_name.blank?
      geom_name = []
      feature_attributes = []
    else
      feat_url = URI("#{url}?service=WFS&request=DescribeFeatureType&version=1.1.0&typeName=#{layer_name}")
      feat_request = get_request(feat_url, 3)
      feat_xml = feat_request.body
      feat_doc = Nokogiri::XML(feat_xml)
      feature_attributes = feat_doc.xpath(ESRI_WFS_XPATH_FEATURES).map(&:value)
      if feature_attributes.empty?
        feature_attributes = feat_doc.xpath(WFS_XPATH_FEATURES).map(&:value)
      end
      geom_name = feat_doc.xpath(ESRI_WFS_XPATH_GEOM).map(&:value)
      if geom_name.blank?
        geom_name = feat_doc.xpath(WFS_XPATH_GEOM).map(&:value)
      end
    end

    [feature_types, geom_name, feature_attributes]
  end

  def get_metadata_esri
    url = source_dataset
    query = {
      f: 'json',
    }
    response = post_request(url + "/layers", query, 3)
    json = JSON.parse(response.body)

    geomFields = ['geometry']
    layers = json['layers']&.map{ |l| l['name'] } || []
    if layers.size == 1
      self.layer_name = layers.first
    end
    options = if layer_name.blank?
                []
              else
                json['layers'].find{ |l| l['name'] == layer_name }['fields'].map{ |f| f['name'] }
              end
    [layers, geomFields, options]
  rescue StandardError => e
    Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
    raise e
  end

  # def self.test_esri
  #   d = new(source_dataset: 'https://services1.arcgis.com/3fjYPqJf7qalQMlb/ArcGIS/rest/services/Control_Points/FeatureServer/0')
  #   d.get_layer_metadata_esri
  # end

  def self.test_esri
    d = new(source_dataset: 'https://services1.arcgis.com/9meaaHE3uiba0zr8/ArcGIS/rest/services/StreetlightsTrafficSignals/FeatureServer/')
    d.layer = {"id"=>12, "name"=>"Street Lighting System Lines"}
    d.get_metadata
  end

  def self.test_wfs
    source_dataset = "WFS:https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer"
    d = new(source_dataset: source_dataset)
    d.get_metadata_wfs_xml
  end

  def self.test_wfs2
    source_dataset = "https://pwgeo.org/datasets/UTILITIES_COMM/STREET_LIGHTING_SYSTEM/street_lighting_system_public.map?"
    d = new(source_dataset: source_dataset)
    d.get_metadata_wfs_xml
  end

  private

  def get_request(url, timeout)
    HTTParty.get(url, timeout: timeout)
  end

  def post_request(url, query, timeout)
    HTTParty.post(url, body: query, timeout: timeout)
  rescue StandardError => e
    Rails.logger.error('ArcGIS query: ' \
                       "#{url}?" \
                       "#{query.map { |k, v| "#{k}=#{v}" }.join('&')}")
    raise e
  end
end
