require 'httparty'

class Dataset < ApplicationRecord
  belongs_to :owner
  has_many :test_tickets, ->{ order(publish_date: :desc) }, class_name: 'Ticket'
  has_many :ticket_dataset_statuses, through: :test_tickets

  attribute :layers, default: []
  attribute :layer, default: {}

  validates :name, :source_dataset, :source_sql, presence: true

  attr_accessor :geometry_name, :layer_name, :feature_class,
                :status_id, :size, :depth, :accuracy_value,
                :description, :layer_selected

  validates :geometry_name, :layer_name, :feature_class,
            :status_id, presence: true, on: :create

  before_validation :set_sql_from_template, on: :create

  def set_sql_from_template
    sql_template = <<-END_SQL
   SELECT
       id,
       "#{geometry_name}" geom,
       "#{feature_class}" feature_class,
       "#{status_id}" status_id,
       "#{size}" size,
       "#{depth}" depth,
       "#{accuracy_value}" accuracy_value,
       "#{description}" description
    FROM
      "#{layer_name}"
    END_SQL
    self.source_sql = sql_template
  end

  def get_metadata
    if source_dataset&.downcase.include?('featureserver')
      get_metadata_esri
    else
      get_metadata_wfs_xml
    end
  end

  def get_metadata_wfs_xml
    url = source_dataset.sub('WFS:', '')
    cap_url = URI("#{url}?service=WFS&request=GetCapabilities")
    cap_request = get_request(cap_url, 3)
    cap_xml = cap_request.body
    cap_doc = Nokogiri::XML(cap_xml)
    feature_types = cap_doc.xpath('//wfs:FeatureType/wfs:Name').map(&:text)
    feat_url = URI("#{url}?service=WFS&request=DescribeFeatureType&typeName=#{feature_types.first}")
    feat_request = get_request(feat_url, 3)
    feat_xml = feat_request.body
    feat_doc = Nokogiri::XML(feat_xml)
	  feature_attributes = feat_doc.xpath("//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@name and not(@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType')]/@name").map(&:value)
    geom_name = feat_doc.xpath("//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType']/@name").map(&:value)
    [feature_types, geom_name, feature_attributes]
  end

  def get_metadata_esri
    query = {
      f: 'json',
    }
    response = post_request(source_dataset + "/layers", query, 3)
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
    d = new(source_dataset: 'https://services1.arcgis.com/9meaaHE3uiba0zr8/ArcGIS/rest/services/Streetlights_And_Traffic_Signals/FeatureServer/')
    d.layer = {"id"=>12, "name"=>"Street Lighting System Lines"}
    d.get_metadata
  end

  def self.test_wfs
    source_dataset = "WFS:https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer"
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
