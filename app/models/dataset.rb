# frozen_string_literal: true

require 'httparty'
require 'uri'
require 'cgi'

class Dataset < ApplicationRecord
  include Normalization

  WFS = 'WFS:'
  ESRIJSON = 'ESRIJSON:'
  ESRI_QUERY_DEFAULT = 'f=json&where=1%3D1&outFields=*&resultRecordCount=1000'

  GEOM_TYPES_BASE = [
    'gml:PointPropertyType',
    'gml:LineStringPropertyType',
    'gml:PolygonPropertyType',
    'gml:GeometryPropertyType',
    'gml:MultiPointPropertyType',
    'gml:MultiLineStringPropertyType',
    'gml:MultiPolygonPropertyType',
    'gml:CurvePropertyType',
    'gml:SurfacePropertyType',
    'gml:MultiCurvePropertyType',
    'gml:MultiSurfacePropertyType',
    'gml:CompositeCurvePropertyType',
    'gml:CompositeSurfacePropertyType',
    'gml:OrientableSurfacePropertyType',
    'gml:RingPropertyType',
    'gml:LinearRingPropertyType',
    'gml:GeometryCollectionPropertyType',
    'gml:MultiGeometryPropertyType'
  ]
  GEOM_TYPES = GEOM_TYPES_BASE.map { |g| "@type='#{g}'" }.join(' or ')
  WFS_XPATH_GEOM = "//xsd:complexType//xsd:element[#{GEOM_TYPES}]/@name"
  WFS_XPATH_FEATURES = "//xsd:complexType//xsd:element[@name and not(#{GEOM_TYPES})]/@name"
  ESRI_WFS_XPATH_GEOM = "//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[#{GEOM_TYPES}]/@name"
  ESRI_WFS_XPATH_FEATURES = "//xsd:extension[@base='gml:AbstractFeatureType']//xsd:element[@name and not(#{GEOM_TYPES})]/@name"

  belongs_to :owner
  belongs_to :service_authentication_configuration, foreign_key: :credential_id, required: false
  has_many :test_tickets, -> { order(publish_date: :desc) }, class_name: 'Ticket', dependent: :destroy
  has_many :ticket_dataset_statuses, through: :test_tickets, dependent: :destroy

  attribute :layers, default: []
  attribute :layer, default: {}
  attribute :order_by, :string, default: 'OBJECTID'

  attr_accessor :geometry_name, :layer_name, :feature_class,
                :status, :size, :depth, :accuracy_class,
                :description, :source_error, :provider_fid,
                :source_co_v

  validates :name, :source_dataset, :source_sql, :source_srs, presence: true
  validates :name, :source_dataset, :source_sql, :source_srs, presence: true, on: :basic
  validates :geometry_name, :provider_fid, :layer_name, :feature_class,
            :status, presence: true, on: :create

  before_validation :set_sql_from_template, on: :create
  before_validation :set_source_co, on: :update
  after_validation :update_order_by_fields, on: :create

  normalizes :name, :source_srs, :source_dataset, with: ->(attr) { attr&.strip }

  def set_source_co
    return if source_co_v.blank?

    self.source_co = source_co_v.split(',')
  end

  def update_order_by_fields
    return unless esrijson? && order_by.present?

    source_dataset.sub!('OBJECTID', order_by)
  end

  def set_sql_from_template
    sql_template = <<-END_SQL
    SELECT
       "#{geometry_name}" as geom,
       #{sqlquote(:provider_fid)},
       #{sqlquote(:feature_class)},
       #{sqlquote(:status)},
       #{sqlquote(:size)},
       #{sqlquote(:depth)},
       #{sqlquote(:accuracy_class)},
       #{sqlquote(:description)}
     FROM
       #{layer_name_for_source}
     ;
    END_SQL
    self.source_sql = sql_template
  end

  def esrijson?
    source_dataset&.starts_with?(ESRIJSON)
  end

  def layer_name_for_source
    if esrijson?
      'ESRIJSON'
    else
      "\"#{layer_name}\""
    end
  end

  def sqlquote(val)
    result = send(val)
    if result.blank?
      "null as #{val}"
    else
      "\"#{send(val)}\" as #{val}"
    end
  end

  def get_metadata
    if esrijson?
      return esri_metadata
    elsif source_dataset.starts_with?(WFS)
      return wfs_metadata
    end

    raise "Valid sources start with 'WFS:', or 'ESRIJSON:'."
  end

  def clean_wfs_url(url_string)
    uri = URI.parse(url_string)
    raise 'Invalid URL' unless uri.scheme && uri.host

    modified_query = if uri.query.present?
                       params = CGI.parse(uri.query)
                       params.delete('service')
                       params.delete('request')
                       tmp = []
                       params.each do |k, v|
                         tmp << "#{k}=#{v.first}" if v.first.present?
                       end
                       tmp.join('&')
                     end
    base_url = "#{uri.scheme}://#{uri.host}#{uri.path}"
    [base_url, modified_query]
  end

  def wfs_metadata
    url = source_dataset.sub(WFS, '')
    clean_base, clean_query = clean_wfs_url(url)

    cap_url = "#{clean_base}?service=WFS&request=GetCapabilities&#{clean_query}"
    cap_xml = get_wfs_capabilities(cap_url)
    feature_types = parse_get_capabilities(cap_xml)
    self.layer_name = feature_types.first if feature_types.size == 1

    if layer_name.blank?
      geom_name = []
      feature_attributes = []
    else
      feat_url = "#{clean_base}?service=WFS&request=DescribeFeatureType&version=1.1.0&typeName=#{layer_name}&#{clean_query}"
      feat_xml = get_wfs_describe_feature(feat_url)
      feature_attributes, geom_name = parse_describe_feature(feat_xml)
    end
    # WFS urls must end with a ? or & b/c additional parameters are added to ogrinfo in FV-Engine
    self.source_dataset = "WFS:#{clean_base}#{clean_query.present? ? "?#{clean_query}&" : '?'}"
    [feature_types, geom_name, feature_attributes]
  rescue StandardError => e
    Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
    raise e
  end

  def esri_metadata
    url = source_dataset.sub(ESRIJSON, '')
    json = post_esri_layers(url)

    geom_fields = ['geometry']
    json_layers = json['layers'] || []
    layer_names = json_layers&.map { |l| l['name'] } || []

    regex = %r{/#{esri_service_type(url)}/(\d+)(/|/query|)}
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
      "#{format_feature_server_url(uri.path, layer_id)}" \
      "#{uri.query.present? ? validate_esri_query_string(uri.query) : esri_query_default}"
    self.source_dataset = tmp

    # ESRIJSON urls must end with a &
    source_dataset.chomp!('&')
    self.source_dataset = "#{source_dataset}&"
  end

  def esri_query_default
    tmp = "&orderByFields=#{order_by}&"
    ESRI_QUERY_DEFAULT + tmp
  end

  def format_feature_server_url(path, layer_id)
    path.chomp!('/')
    path.chomp!('/query')
    if path.ends_with?(layer_id.to_s)
      "#{path}/query?"
    else
      "#{path}/#{layer_id}/query?"
    end
  end

  def validate_esri_query_string(query_string)
    expected_keys = %w[f where outFields orderByFields resultRecordCount]
    parsed_params = CGI.parse(query_string)
    actual_keys = parsed_params.keys
    missing_keys = expected_keys - actual_keys

    if missing_keys.any?
      raise "Missing query parmeters: #{missing_keys.join(', ')}. ESRIJSON requires a query string similar to the following: '#{esri_query_default}'"
    end

    query_string
  end

  private

  def parse_get_capabilities(xml)
    cap_doc = Nokogiri::XML(xml)
    cap_doc.remove_namespaces!
    cap_doc.xpath('//FeatureType/Name').map(&:text)
  end

  def parse_describe_feature(xml)
    feat_doc = Nokogiri::XML(xml)
    feature_attributes = feat_doc.xpath(ESRI_WFS_XPATH_FEATURES).map(&:value)
    feature_attributes = feat_doc.xpath(WFS_XPATH_FEATURES).map(&:value) if feature_attributes.empty?
    geom_name = feat_doc.xpath(ESRI_WFS_XPATH_GEOM).map(&:value)
    geom_name = feat_doc.xpath(WFS_XPATH_GEOM).map(&:value) if geom_name.blank?
    [feature_attributes, geom_name]
  end

  def adjusted_esri_url(url)
    service_type = esri_service_type(url)
    match = url.match(/.*?#{service_type}/)
    return match[0] if match

    raise "Expected the path to include 'FeatureServer' or 'Mapserver'"
  end

  def esri_service_type(url)
    if url.include?('FeatureServer')
      'FeatureServer'
    elsif url.include?('MapServer')
      'MapServer'
    end
  end

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
    auth = if service_authentication_configuration&.basic?
             {
               username: service_authentication_configuration.auth_uid,
               password: service_authentication_configuration.auth_key
             }
           else
             {}
           end
    HTTParty.get(url, timeout: timeout, basic_auth: auth)
  end

  def post_request(url, query, timeout)
    headers = if token = service_authentication_configuration&.esritoken&.fetch('token', nil)
                {'Authorization': "Bearer #{token}"}
              else
                {}
              end
    HTTParty.post(url, body: query, headers: headers, timeout: timeout)
  rescue StandardError => e
    Rails.logger.error('ArcGIS query: ' \
                       "#{url}?" \
                       "#{query.map { |k, v| "#{k}=#{v}" }.join('&')}")
    raise e
  end
end
