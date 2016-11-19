class ApiController < ActionController::Base

  def ranking
    render json:
             [ { name: "Player 1", lastMatch: "2016-11-15" },
               { name: "Player 2", lastMatch: "2016-11-19" },
               { name: "Player 3", lastMatch: "2016-11-18" }
             ]
  end

end
