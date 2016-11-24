class League < ActiveRecord::Base
  has_many :teams

  def api_json
    { "id" => id, "name" => name }
  end
end
