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
    params.required(:id)
    render json: User.find(params[:id]).recent_teams(5).map(&:api_json)
  end

  def stats
    matches = Match.of_user(@current_user)

    render json: {
             "recentMatches" => matches
                               .order(created_at: :desc)
                               .limit(10)
                               .map(&:api_json),

             "versus" => versus_stats(matches)
           }
  end

  def leagues
    render json: League.all.map(&:api_json)
  end

  def league_teams
    params.required(:id)
    render json: Team.where(league_id: params[:id]).map(&:api_json)
  end

  def report_match
    params.required([:rival_id, :own_goals, :rival_goals, :own_team_id, :rival_team_id])

    if params[:rival_id].to_i == @current_user.id || params[:own_goals].to_i < 0 || params[:rival_goals].to_i < 0
      return head 400
    end

    Match.create!(
      user1_id: @current_user.id,
      user1_team_id: params[:own_team_id],
      user1_goals: params[:own_goals],

      user2_id: params[:rival_id],
      user2_team_id: params[:rival_team_id],
      user2_goals: params[:rival_goals]
    )

    return head 204
  end

  private

  def authenticate
    unless session[:user_id]
      head 401
      return false
    end

    set_current_user
  end

  def versus_stats(matches)
    matches.map { |m| m.participations_for(@current_user) }
      .group_by { |match| match["rival"]["id"] }
      .map do |rival_id, rival_matches|
      won = 0
      tied = 0
      lost = 0
      goals_made = 0
      goals_received = 0

      rival_matches.each do |match|
        own_goals = match["own"]["goals"]
        rival_goals = match["rival"]["goals"]

        case own_goals <=> rival_goals
        when 1
          won += 1
        when -1
          lost += 1
        else
          tied += 1
        end

        goals_made += own_goals
        goals_received += rival_goals
      end

      {
        "rivalName" => rival_matches.first["rival"]["name"],
        "won" => won,
        "tied" => tied,
        "lost" => lost,
        "goalsMade" => goals_made,
        "goalsReceived" => goals_received
      }
    end
  end

end
