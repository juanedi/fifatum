class ApiController < ApplicationController

  before_action :authenticate

  def ranking
    # TODO
    render json:
             [ { name: "Player 1", lastMatch: "2016-11-15" },
               { name: "Player 2", lastMatch: "2016-11-19" },
               { name: "Player 3", lastMatch: "2016-11-18" }
             ]
  end

  def stats
    matches = Match.of_user(@current_user)
                   .order(created_at: :desc)
                   .limit(10)

    render json: {
      "recentMatches" => matches.map(&:api_json)
    }
  end

  private

  def authenticate
    unless session[:user_id]
      head 401
      return false
    end

    set_current_user
  end

end
