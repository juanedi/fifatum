class Match < ActiveRecord::Base

  belongs_to :user1, class_name: User, foreign_key: :user1_id
  belongs_to :team1, class_name: Team, foreign_key: :user1_team_id

  belongs_to :user2, class_name: User, foreign_key: :user2_id
  belongs_to :team2, class_name: Team, foreign_key: :user2_team_id

  def self.of_user(user)
    Match.where("user1_id = ? OR user2_id = ?", user.id, user.id)
         .includes(:user1).includes(:team1)
         .includes(:user2).includes(:team2)
  end

  def api_json
    {
      "id" => id,
      "user1" => {
        "id" => user1.id,
        "name" => user1.name,
        "team" => { "id" => team1.id, "name" => team1.name },
        "goals" => 3
      },
      "user2" => {
        "id" => user2.id,
        "name" => user2.name,
        "team" => { "id" => team2.id, "name" => team2.name },
        "goals" => 1
      }
    }
  end

end
