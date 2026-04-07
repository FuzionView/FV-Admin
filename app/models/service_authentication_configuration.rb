class ServiceAuthenticationConfiguration < ApplicationRecord
  self.table_name = :credentials
  belongs_to :owner
  belongs_to :authentication_type, foreign_key: :auth_type, class_name: "AuthType"
  has_many :datasets, foreign_key: :credential_id
  validates :auth_type, :name, presence: true
  validates :auth_uid, :auth_key, presence: true, if: :basic?
  validates :auth_key, presence: true, if: :bearer?

  delegate :basic?, to: :authentication_type, allow_nil: true
  delegate :bearer?, to: :authentication_type, allow_nil: true


  def before_destroy
    return true if datasets.count == 0

    errors.add(:base, :credentials_assigned)
    throw(:abort)
  end

  def label
    "#{name} (#{authentication_type&.name})"
  end

  def fetch_token
    if auth_type == "Bearer"
      auth_key
    elsif auth_type == "ESRIToken"
      esritoken.fetch("token", nil)
    elsif auth_type == "OAuth2 Client"
      oauth2.fetch("access_token", nil)
    end
  end

  def test_configuration
    raise "Not implemented" unless [ "ESRIToken", "OAuth2 Client" ].include?(auth_type)

    test_token
  end

  def oauth2
    query = { client_id: auth_uid,
              client_secret: auth_key,
              grant_type: "client_credentials" }
    raw_response = post_request(auth_url, query, 3)
    JSON.parse(raw_response.body)
  end

  def esritoken
    query = { f: "json",
              username: auth_uid,
              password: auth_key,
              referer: "https://www.arcgis.com",
              client: "referer" }
    raw_response = post_request(auth_url, query, 3, { 'Content-Type': "application/x-www-form-urlencoded" })
    JSON.parse(raw_response.body)
  end

  def test_token
    json_response = auth_type == "ESRIToken" ? esritoken : oauth2
    if json_response.fetch("token", nil) || json_response.fetch("access_token", nil)
      "SUCCESS"
    else
      msg = "#{json_response.dig('error', 'message')} #{json_response.dig('error', 'details')&.join}"
      raise msg
    end
  end

  def post_request(url, query, timeout, headers = {})
    HTTParty.post(url, body: query, timeout: timeout, headers: headers)
  rescue StandardError => e
    Rails.logger.error("POST: " \
                       "#{url}?" \
                       "#{query.map { |k, v| "#{k}=#{v}" }.join('&')}")
    raise e
  end
end
