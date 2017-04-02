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

  def self.between(user1_id, user2_id)
    Match.where("(user1_id = ? AND user2_id = ?) OR (user1_id = ? and user2_id = ?)", user1_id, user2_id, user2_id, user1_id)
         .includes(:user1).includes(:team1)
         .includes(:user2).includes(:team2)
         .order(created_at: :asc)
  end

  def self.last_of(user)
    Match.of_user(user)
         .order(created_at: :desc)
         .first
  end

  def api_json
    {
      "id" => id,
      "date" => created_at.to_i,
      "user1" => {
        "id" => user1.id,
        "name" => user1.name,
        "team" => { "id" => team1.id, "name" => team1.name },
        "goals" => user1_goals
      },
      "user2" => {
        "id" => user2.id,
        "name" => user2.name,
        "team" => { "id" => team2.id, "name" => team2.name },
        "goals" => user2_goals
      }
    }
  end

  def participations_for(user)
    p1 = {
      "id" => user1.id,
      "name" => user1.name,
      "team" => { "id" => team1.id, "name" => team1.name },
      "goals" => user1_goals
    }

    p2 = {
      "id" => user2.id,
      "name" => user2.name,
      "team" => { "id" => team2.id, "name" => team2.name },
      "goals" => user2_goals
    }

    if user1 == user
      { "own" => p1, "rival" => p2 }
    else
      { "own" => p2, "rival" => p1 }
    end
  end

end
