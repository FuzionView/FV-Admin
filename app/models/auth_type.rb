class AuthType < ApplicationRecord
  self.table_name = :auth_type

  def basic?
    id == 'Basic'
  end

  def bearer?
    id == 'Bearer'
  end
end
