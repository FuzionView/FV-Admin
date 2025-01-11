# frozen_string_literal: true

require 'httparty'
require 'uri'
require 'cgi'

class Dataset < ApplicationRecord
  WFS = 'WFS:'
  ESRIJSON = 'ESRIJSON:'
  ESRI_QUERY_DEFAULT = 'f=json&where=1%3D1&outFields=*&orderByFields=OBJECTID&resultRecordCount=1000&'

  WFS_XPATH_GEOM = "//xsd:complexType//xsd:element[@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType']/@name"
  ESRI_WFS_XPATH_GEOM = "//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType']/@name"
  WFS_XPATH_FEATURES = "//xsd:complexType//xsd:element[@name and not(@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType')]/@name"
  ESRI_WFS_XPATH_FEATURES = "//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@name and not(@type='gml:GeometryPropertyType' or @type='gml:PointPropertyType' or @type='gml:LineStringPropertyType')]/@name"

  belongs_to :owner
  has_many :test_tickets, -> { order(publish_date: :desc) }, class_name: 'Ticket', dependent: :destroy
  has_many :ticket_dataset_statuses, through: :test_tickets, dependent: :destroy

  attribute :layers, default: []
  attribute :layer, default: {}

  validates :name, :source_dataset, :source_sql, :source_srs, presence: true
  validates :name, :source_dataset, :source_sql, :source_srs, presence: true, on: :basic

  attr_accessor :geometry_name, :layer_name, :feature_class,
                :status_id, :size, :depth, :accuracy_value,
                :description, :source_error, :owner_fid,
                :source_co_v

  validates :geometry_name, :owner_fid, :layer_name, :feature_class,
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
       "#{geometry_name}" geom,
       #{sqlquote(:owner_fid)},
       #{sqlquote(:feature_class)},
       #{sqlquote(:status_id)},
       #{sqlquote(:size)},
       #{sqlquote(:depth)},
       #{sqlquote(:accuracy_value)},
       #{sqlquote(:description)}
     FROM
       #{layer_name_for_source}
     ;
    END_SQL
    self.source_sql = sql_template
  end

  def layer_name_for_source
    if source_dataset&.starts_with?(ESRIJSON)
      'ESRIJSON'
    else
      "\"#{layer_name}\""
    end
  end

  def sqlquote(val)
    result = eval(val.to_s)
    if result.blank?
      "null #{val}"
    else
      "\"#{eval(val.to_s)}\" #{val}"
    end
  end

  def get_metadata
    if source_dataset.starts_with?(ESRIJSON)
      return get_metadata_esri
    elsif source_dataset.starts_with?(WFS)
      return get_metadata_wfs_xml
    end

    raise "Valid sources start with 'WFS:', or 'ESRIJSON:'."
  end

  def get_metadata_wfs_xml
    url = source_dataset.sub(WFS, '').sub('?', '')
    tmp = URI(url)
    raise 'A URL with a host is required' unless tmp.host

    cap_url = URI("#{url}?service=WFS&request=GetCapabilities")
    cap_xml = get_wfs_capabilities(cap_url)
    cap_doc = Nokogiri::XML(cap_xml)
    feature_types = cap_doc.xpath('//wfs:FeatureType/wfs:Name').map(&:text)
    self.layer_name = feature_types.first if feature_types.size == 1

    if layer_name.blank?
      geom_name = []
      feature_attributes = []
    else
      feat_url = URI("#{url}?service=WFS&request=DescribeFeatureType&version=1.1.0&typeName=#{layer_name}")
      feat_xml = get_wfs_describe_feature(feat_url)
      feat_doc = Nokogiri::XML(feat_xml)
      feature_attributes = feat_doc.xpath(ESRI_WFS_XPATH_FEATURES).map(&:value)
      feature_attributes = feat_doc.xpath(WFS_XPATH_FEATURES).map(&:value) if feature_attributes.empty?
      geom_name = feat_doc.xpath(ESRI_WFS_XPATH_GEOM).map(&:value)
      geom_name = feat_doc.xpath(WFS_XPATH_GEOM).map(&:value) if geom_name.blank?
    end
    # WFS urls must end with a ?
    source_dataset.chomp!('?')
    self.source_dataset = "#{source_dataset}?"
    [feature_types, geom_name, feature_attributes]
  rescue StandardError => e
    Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
    raise e
  end

  def get_metadata_esri
    url = source_dataset.sub(ESRIJSON, '')
    json = post_esri_layers(url)

    geom_fields = ['geometry']
    json_layers = json['layers'] || []
    layer_names = json_layers&.map { |l| l['name'] } || []

    regex = /\/#{esri_service_type(url)}\/(\d+)(\/|\/query|)/
    layer_id = if (match = url.match(regex))
                 match[1]
               end
    options = []
    tmp_layer = nil

    if json_layers.empty?
      raise 'No layers identified.'
    elsif json_layers.size == 1
      self.layer_name = layer_names.first
      tmp_layer = json_layers.first
      layer_id = tmp_layer['id']
      options = tmp_layer['fields'].map { |f| f['name'] }
    elsif json_layers.size > 1

      tmp_layer = if layer_id.present?
                    json_layers.find { |l| l['id'] == layer_id.to_i }
                  else
                    json_layers.find { |l| l['name'] == layer_name }
                  end
      if tmp_layer
        layer_id = tmp_layer['id']
        self.layer_name = tmp_layer['name']
        options = tmp_layer['fields'].map { |f| f['name'] }
      end
    end

    rebuild_esri_url(url, layer_id)
    [layer_names, geom_fields, options]
  rescue StandardError => e
    Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
    raise e
  end

  def rebuild_esri_url(url, layer_id)
    return if layer_id.blank? # Not enough info

    # rebuild url and add query
    uri = URI(url)
    tmp = "#{ESRIJSON}#{uri.scheme}://" \
      "#{uri.host}" \
      "#{format_feature_server_url(uri.path)}" \
      "#{uri.query.present? ? validate_esri_query_string(uri.query) : ESRI_QUERY_DEFAULT}"
    self.source_dataset = tmp

    # ESRIJSON urls must end with a &
    source_dataset.chomp!('&')
    self.source_dataset = "#{source_dataset}&"
  end

  def format_feature_server_url(path)
    path.chomp!('/')
    path.chomp!('/query')
    "#{path}/query?"
  end

  def adjusted_esri_url(url)
    service_type = esri_service_type(url)
    match = url.match(/.*?#{service_type}/)
    return match[0] if match

    raise "Expected the path to include 'FeatureServer' or 'Mapserver'"
  end

  def esri_service_type(url)
    if  url.include?('FeatureServer')
      'FeatureServer'
    elsif url.include?('MapServer')
      'MapServer'
    end
  end

  def validate_esri_query_string(query_string)
    expected_keys = %w[f where outFields orderByFields resultRecordCount]
    parsed_params = CGI.parse(query_string)
    actual_keys = parsed_params.keys
    missing_keys = expected_keys - actual_keys

    if missing_keys.any?
      raise "Missing query parmeters: #{missing_keys.join(', ')}. ESRIJSON requires a query string similar to the following: '#{ESRI_QUERY_DEFAULT}'"
    end

    query_string
  end

  private

  def post_esri_layers(url)
    base_query_url = adjusted_esri_url(url)
    query = { f: 'json' }
    response = post_request("#{base_query_url}/layers", query, 3)
    JSON.parse(response.body)
  end

  def get_wfs_capabilities(url)
    cap_request = get_request(url, 3)
    cap_request.body
  end

  def get_wfs_describe_feature(url)
    feat_request = get_request(url, 3)
    feat_request.body
  end

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
