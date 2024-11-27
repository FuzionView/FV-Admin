require 'httparty'
require 'uri'
require 'cgi'

class Dataset < ApplicationRecord
  WFS = 'WFS:'
  ESRIJSON = 'ESRIJSON:'
  ESRI_QUERY_DEFAULT = 'f=json&where=1%3D1&outFields=*&orderByFields=OBJECTID&resultRecordCount=1000'

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
  validates :name, :source_dataset, :source_sql, presence: true, on: :basic

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
    if source_dataset.starts_with?(ESRIJSON, 'http')
      'ESRIJSON'
    else
      "\"#{layer_name}\""
    end
  end

  def sqlquote(val)
    result = eval(val.to_s)
    if result.blank?
      "null #{val.to_s}"
    else
      "\"#{eval(val.to_s)}\" #{val.to_s}"
    end
  end

  def get_metadata
    if source_dataset.starts_with?(ESRIJSON, 'http') &&
        source_dataset&.downcase.include?('featureserver')
      return get_metadata_esri
    elsif source_dataset.starts_with?(WFS)
      return get_metadata_wfs_xml
    elsif source_dataset.starts_with?('./')
      self.source_srs = 'EPSG:6344'
      self.layer_name = 'unknown'
      self.feature_class = 'unknown'
      self.status_id = 'unknown'
      self.geometry_name = 'geometry'
      return [['unknown'], ['geometry'], ['unknown']]
    end

    raise "Valid sources start with 'WFS:', or 'ESRIJSON:'."
  end

  def get_metadata_wfs_xml
    url = source_dataset.sub(WFS, '').sub('?', '')
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
    url = source_dataset.sub(ESRIJSON, '')
    base_query_url = adjusted_esri_url(url)

    query = {
      f: 'json',
    }
    response = post_request(base_query_url + "/layers", query, 3)
    json = JSON.parse(response.body)

    geomFields = ['geometry']
    layer_names = json['layers']&.map{ |l| l['name'] } || []
    json_layers = json['layers'] || []
    pattern = /FeatureServer\/(\d+)\/query\?/
    layer_id = if match = url.match(pattern)
                 match[1]
               end
    options = []
    tmp_layer = nil

    if json_layers.size == 0
      raise "No layers identified."
    elsif json_layers.size == 1
      self.layer_name = layer_names.first
      tmp_layer = json_layers.first
      layer_id = tmp_layer['id']
      options = tmp_layer['fields'].map{ |f| f['name'] }
    elsif json_layers.size > 1
      tmp_layer = if layer_id.present?
                    json_layers.find{ |l| l['id'] == layer_id.to_i }
                  else
                    json_layers.find{ |l| l['name'] == layer_name }
                  end
      if tmp_layer
        layer_id = tmp_layer['id']
        self.layer_name = tmp_layer['name']
        options = tmp_layer['fields'].map{ |f| f['name'] }
      end
    end

    rebuild_esri_url(url, layer_id)
    [layer_names, geomFields, options]
  rescue StandardError => e
    Rails.logger.error("Error: #{e.message}: \n\t#{e.backtrace.join("\n\t")}")
    raise e
  end

  def rebuild_esri_url(url, layer_id)
    return if layer_id.blank?  # Not enough info

    uri = URI(url)
    query_string = uri.query

    if url.match(/FeatureServer\/\d+\/query\?/) && query_string
      validate_esri_query_string(query_string)
    else
      # rebuild url and add query
      uri = URI(url)
      tmp = "#{ESRIJSON}#{uri.scheme}://" +
      "#{uri.host}" +
      "#{format_feature_server_url(uri.path, layer_id)}" +
      "#{query_string.present? ? validate_esri_query_string(query_string) : ESRI_QUERY_DEFAULT}"
      self.source_dataset = tmp
    end
  end

  def format_feature_server_url(url, number)
    formatted_url = url.sub(%r{FeatureServer/(\d+)?(query\?)?}, "FeatureServer/#{number}/query?")
    formatted_url += "/query?" unless formatted_url.include?("/query?")
    formatted_url.gsub('?/', '?')
  end

  def adjusted_esri_url(url)
    match = url.match(/.*?FeatureServer/)
    return match[0] if match

    raise "Expected the path to include 'FeatureServer'"
  end

  def validate_esri_query_string(query_string)
    expected_keys = %w[f where outFields orderByFields resultRecordCount]
    parsed_params = CGI.parse(query_string)
    actual_keys = parsed_params.keys
    missing_keys = expected_keys - actual_keys

    if missing_keys.any?
      raise "Missing query parmeters: #{missing_keys.join(', ')}. ESRIJSON requires a query string similar to the following: '#{ESRI_QUERY_DEFAULT}'"
    else
      query_string
    end
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
