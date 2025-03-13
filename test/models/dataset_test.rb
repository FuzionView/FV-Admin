require 'test_helper'

class DatasetTest < ActiveSupport::TestCase
  setup do
    @valid_attributes = {
      name: 'Test Dataset',
      source_dataset: 'WFS:http://example.com/wfs',
      source_sql: 'SELECT * FROM test_layer;',
      source_srs: 'EPSG:26915'
    }
    @owner = owners(:one)
    @dataset = @owner.datasets.build(@valid_attributes)
  end

  test 'should be valid with valid attributes' do
    assert @dataset.valid?(context: :basic), "#{@dataset.errors.inspect}"
  end

  test 'should be invalid without a name' do
    @dataset.name = nil
    assert_not @dataset.valid?
    assert_includes @dataset.errors[:name], "can't be blank"
  end

  test 'should be invalid without a source_dataset' do
    @dataset.source_dataset = nil
    assert_not @dataset.valid?
    assert_includes @dataset.errors[:source_dataset], "can't be blank"
  end

  test 'should be invalid without a source_sql' do
    @dataset.source_sql = nil
    assert_not @dataset.valid?(context: :update)
    assert_includes @dataset.errors[:source_sql], "can't be blank"
  end

  test 'should set SQL from template on create' do
    @dataset.geometry_name = 'geom'
    @dataset.layer_name = 'test_layer'
    @dataset.valid? # Trigger callbacks
    assert_match(/SELECT/, @dataset.source_sql)
  end

  test 'should set source_co from source_co_v on update' do
    @dataset.source_co_v = 'value1,value2,value3'
    @dataset.set_source_co
    assert_equal %w[value1 value2 value3], @dataset.source_co
  end

  test 'get_metadata should raise error for invalid source_dataset' do
    @dataset.source_dataset = 'INVALID:source'
    assert_raises(RuntimeError) { @dataset.get_metadata }
  end

  test 'wfs_metadata should return metadata' do
    @dataset.source_dataset = 'WFS:http://example.com/wfs?'
    mock_capabilities_response = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <wfs:WFS_Capabilities xmlns="http://www.opengis.net/wfs/2.0" xmlns:wfs="http://www.opengis.net/wfs/2.0" xmlns:ows="http://www.opengis.net/ows/1.1" xmlns:fes="http://www.opengis.net/fes/2.0" xmlns:SURFACE_ITS_UTILITIES="https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="2.0.0" xsi:schemaLocation="http://www.opengis.net/wfs/2.0 http://schemas.opengis.net/wfs/2.0/wfs.xsd https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer?service=wfs%26version=2.0.0%26request=DescribeFeatureType">
       <wfs:FeatureTypeList>
         <wfs:FeatureType>
             <wfs:Name>SURFACE_ITS_UTILITIES:SURFACE_ITS_UTILITIES</wfs:Name>
                 <wfs:Title>SURFACE_ITS_UTILITIES</wfs:Title>
                     <wfs:DefaultCRS>urn:ogc:def:crs:EPSG::3857</wfs:DefaultCRS>
                         <ows:WGS84BoundingBox>
                           <ows:LowerCorner>-96.97668711 43.50808472</ows:LowerCorner>
                           <ows:UpperCorner>-90.33295545 48.84826396</ows:UpperCorner>
                         </ows:WGS84BoundingBox>
         </wfs:FeatureType>
       </wfs:FeatureTypeList>
      </wfs:WFS_Capabilities>
    XML

    mock_feature_response = <<-XML
		<?xml version="1.0" encoding="UTF-8"?>
		<xsd:schema xmlns:SURFACE_ITS_UTILITIES="https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:gml="http://www.opengis.net/gml" targetNamespace="https://webgist.dot.state.mn.us/65ags/services/Hosted/SURFACE_ITS_UTILITIES/MapServer/WFSServer" elementFormDefault="qualified" attributeFormDefault="unqualified">
		<xsd:import namespace="http://www.opengis.net/gml" schemaLocation="http://schemas.opengis.net/gml/3.1.1/base/gml.xsd"/>
		<xsd:element name="SURFACE_ITS_UTILITIES" type="SURFACE_ITS_UTILITIES:SURFACE_ITS_UTILITIESFeatureType" substitutionGroup="gml:_Feature"/>
		<xsd:complexType name="SURFACE_ITS_UTILITIESFeatureType">
			<xsd:complexContent>
				<xsd:extension base="gml:AbstractFeatureType">
					<xsd:sequence>
						<xsd:element minOccurs="0" maxOccurs="1" name="id" type="xsd:int"/>
						<xsd:element minOccurs="0" maxOccurs="1" name="pkey" type="xsd:int"/>
						<xsd:element minOccurs="0" maxOccurs="1" name="name">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="254"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="feature">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="254"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="subtype">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="80"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="db_pcwby.hsu_0dqty.surface_its_utilities_surface_its_utilities.entity">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="50"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="functional_group">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="25"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="geometry_source">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="50"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="physical_status">
							<xsd:simpleType>
								<xsd:restriction base="xsd:string">
									<xsd:maxLength value="20"/>
								</xsd:restriction>
							</xsd:simpleType>
						</xsd:element>
						<xsd:element minOccurs="0" maxOccurs="1" name="lat" type="xsd:double"/>
						<xsd:element minOccurs="0" maxOccurs="1" name="lon" type="xsd:double"/>
						<xsd:element minOccurs="0" maxOccurs="1" name="published_date" type="xsd:dateTime"/>
						<xsd:element minOccurs="0" maxOccurs="1" name="OBJECTID" type="xsd:int"/>
						<xsd:element minOccurs="0" maxOccurs="1" name="SHAPE" type="gml:PointPropertyType"/>
					</xsd:sequence>
				</xsd:extension>
			</xsd:complexContent>
		</xsd:complexType>
		</xsd:schema>
    XML

    Dataset.any_instance.stubs(:get_wfs_capabilities).returns(mock_capabilities_response)
    Dataset.any_instance.stubs(:get_wfs_describe_feature).returns(mock_feature_response)
    feature_types, geom_name, feature_attributes = @dataset.wfs_metadata
    assert_equal ['SURFACE_ITS_UTILITIES:SURFACE_ITS_UTILITIES'], feature_types
    assert geom_name
    assert feature_attributes
  end

  test 'esri_metadata should return metadata from FeatureServer' do
    @dataset.source_dataset = 'ESRIJSON:http://example.com/FeatureServer/1'
    mock_response = {
      'layers' => [
        { 'id' => 0, 'name' => 'Layer1', 'fields' => [{ 'name' => 'field1' }, { 'name' => 'field2' }] },
        { 'id' => 1, 'name' => 'Layer2', 'fields' => [{ 'name' => 'field1' }, { 'name' => 'field2' }] }
      ]
    }.to_json
    HTTParty.stubs(:post).returns(stub(body: mock_response))
    layer_names, geom_fields, options = @dataset.esri_metadata
    assert_equal %w[Layer1 Layer2], layer_names
    assert_equal ['geometry'], geom_fields
    assert_equal %w[field1 field2], options
  end

  test 'esri_metadata should return metadata from MapServer' do
    @dataset.source_dataset = 'ESRIJSON:http://example.com/MapServer'
    mock_response = {
      'layers' => [
        { 'id' => 0, 'name' => 'Layer1', 'fields' => [{ 'name' => 'field1' }, { 'name' => 'field2' }] }
      ]
    }.to_json
    HTTParty.stubs(:post).returns(stub(body: mock_response))
    layer_names, geom_fields, options = @dataset.esri_metadata
    assert_equal ['Layer1'], layer_names
    assert_equal ['geometry'], geom_fields
    assert_equal %w[field1 field2], options
  end

  test 'format sql' do
    @dataset.provider_fid = 'objectid'
    @dataset.geometry_name = 'geom'
    @dataset.set_sql_from_template
    assert_equal @dataset.source_sql,
                 "    SELECT
       \"geom\" as geom,
       \"objectid\" as provider_fid,
       null as feature_class,
       null as status,
       null as size,
       null as depth,
       null as accuracy_class,
       null as description
     FROM
       \"\"
     ;
"
  end

  test 'format map server url' do
    path = '/test/MapServer/1'
    formatted_url = @dataset.format_feature_server_url(path, 1)
    assert formatted_url.include?('MapServer/1/query?')
  end

  test 'can rebuild url' do
    url = 'https://example.com/MapServer/1'
    formatted_url = @dataset.rebuild_esri_url(url, 1)
    assert formatted_url.include?(url)
  end

  test 'can rebuild url with query' do
    url = 'https://example.com/MapServer/1/query?f=json&where=1%3D1&outFields=*&orderByFields=OBJECTID&resultRecordCount=1000&'
    formatted_url = @dataset.rebuild_esri_url(url, 1)
    assert formatted_url.include?(url), "was #{formatted_url}"
  end

  test 'removes service and request params' do
    url = 'http://example.com/path?service=test&request=123&par
am1=a&param2=b'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_equal 'param1=a&param2=b', modified_query
  end

  test 'no service or request params' do
    url = 'http://example.com/path?param1=a&param2=b'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_equal 'param1=a&param2=b', modified_query
  end

  test 'only service param' do
    url = 'http://example.com/path?service=test&param1=a'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_equal 'param1=a', modified_query
  end

  test 'no query string' do
    url = 'http://example.com/path'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_nil modified_query
  end

  test 'only service and request params' do
    url = 'http://example.com/path?service=test&request=123'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_empty modified_query
  end

  test 'service and request params trailing ampersand' do
    url = 'http://example.com/path?service=test&request=123&'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_empty modified_query, "expected nil was #{modified_query}"
  end

  test 'empty query string' do
    url = 'http://example.com/path?'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com/path', base_url
    assert_nil modified_query
  end

  test 'empty string' do
    url = ''
    assert_raises(RuntimeError) { @dataset.clean_wfs_url(url) }
  end

  test 'url with no path' do
    url = 'http://example.com?service=test&request=123&param1=a&param2=b'
    base_url, modified_query = @dataset.clean_wfs_url(url)
    assert_equal 'http://example.com', base_url
    assert_equal 'param1=a&param2=b', modified_query
  end
end
