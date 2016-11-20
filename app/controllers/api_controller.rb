class ApiController < ApplicationController

  before_action :authenticate

  def ranking
    render json:
             [ { name: "Player 1", lastMatch: "2016-11-15" },
               { name: "Player 2", lastMatch: "2016-11-19" },
               { name: "Player 3", lastMatch: "2016-11-18" }
             ]
  end

  def user_history
    matches = Match.of_user(@current_user)
    render json: matches.map(&:api_json)
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
