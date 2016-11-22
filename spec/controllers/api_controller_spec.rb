require 'rails_helper'

RSpec.describe ApiController do

  before(:each) do
    User.create(name: "John", email: "john@example.com")
    User.create(name: "Mike", email: "mike@example.com")

    league = League.create(name: "The League")

    Team.create(league: league, name: "Team 1")
    Team.create(league: league, name: "Team 2")
  end

  let(:current_user) { User.find_by_email("john@example.com") }
  let(:other_user)   { User.find_by_email("mike@example.com") }
  let(:t1)   { Team.first }
  let(:t2)   { Team.last }

  context "user is not authenticated" do
    it "redirects user to log in" do
      get :ranking

      expect(response.code.to_i).to eq(401)
      expect(response.body).to be_empty
    end
  end

  context "user is authenticated" do

    before(:each) do
      @request.session[:user_id] = current_user.id
    end

    it "provides access tu the current ranking" do
      # TODO
      get :ranking

      expect(response.code.to_i).to eq(200)

      expect(json_response).to eq([
        {"name"=>"Player 1", "lastMatch"=>"2016-11-15"},
        {"name"=>"Player 2", "lastMatch"=>"2016-11-19"},
        {"name"=>"Player 3", "lastMatch"=>"2016-11-18"}
      ])
    end

    describe "stats" do
      it "returns all relevant match information" do
        match = Match.create(
          user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
          user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
        )

        expect(match.api_json).to eq({
          "id" => match.id,
          "user1" => {
            "id" => current_user.id,
            "name" => current_user.name,
            "team" => { "id" => t1.id, "name" => t1.name },
            "goals" => 3
          },
          "user2" => {
            "id" => other_user.id,
            "name" => other_user.name,
            "team" => { "id" => t2.id, "name" => t2.name },
            "goals" => 1
          }
        })
      end

      describe "recent matches" do
        it "lists the current user's matches" do
          get :stats

          expect(response.code.to_i).to eq(200)
          expect(json_response["recentMatches"]).to eq([])

          match1 = Match.create!(
            user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
            user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
          )

          match2 = Match.create!(
            user1_id: other_user.id, user1_team_id: t1.id, user1_goals: 1,
            user2_id: current_user.id, user2_team_id: t2.id, user2_goals: 0
          )

          get :stats

          expect(response.code.to_i).to eq(200)
          expect(json_response["recentMatches"]).to eq([
            match2.api_json,
            match1.api_json
          ])
        end

        it "returns the last 10 matches" do
          15.times do
            Match.create!(
              user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
              user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
            )
          end

          get :stats

          ids = json_response["recentMatches"].map { |m| m["id"] }
          expect(ids).to eq(Match.order(created_at: :desc).limit(10).map(&:id))
        end
      end
    end
  end


  def json_response
    JSON.parse(response.body)
  end
end
