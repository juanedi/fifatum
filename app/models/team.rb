class Team < ActiveRecord::Base
  belongs_to :league

  def api_json
    { "id" => id, "name" => name }
  end
end
