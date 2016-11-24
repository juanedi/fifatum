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

  def users
    render json: User.all.map(&:api_json)
  end

  def recent_teams
    render json: User.find(params[:id]).recent_teams(5).map(&:api_json)
  end

  def stats
    matches = Match.of_user(@current_user)
                   .order(created_at: :desc)
                   .limit(10)

    render json: {
      "recentMatches" => matches.map(&:api_json)
    }
  end

  def leagues
    render json: League.all.map(&:api_json)
  end

  def league_teams
    render json: Team.where(league_id: params[:id]).map(&:api_json)
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
