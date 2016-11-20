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

    it "provides access to the current user's match history" do
      get :user_history

      expect(response.code.to_i).to eq(200)
      expect(json_response).to eq([])

      t1 = Team.first
      t2 = Team.last

      match = Match.create!(
        user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
        user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
      )

      get :user_history

      expect(response.code.to_i).to eq(200)
      expect(json_response).to eq([
        {
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
        }
      ])
    end
  end


  def json_response
    JSON.parse(response.body)
  end
end
