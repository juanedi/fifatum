class User < ActiveRecord::Base

  def api_json
    { "id" => id, "name" => name }
  end

  def recent_teams(count)
    Match.of_user(self)
         .order(created_at: :desc)
         .map { |match| self.team_in(match) }
         .uniq
         .take(count)
  end

  def team_in(match)
    if match.user1 == self
      match.team1
    elsif match.user2 == self
      match.team2
    else
      raise "User did not participate in match"
    end
  end

end
