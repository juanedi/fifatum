require 'rails_helper'

RSpec.describe ApiController do

  before(:each) do
    User.create(name: "John", email: "john@example.com")
    User.create(name: "Mike", email: "mike@example.com")
    User.create(name: "Peter", email: "peter@example.com")

    league = League.create(name: "The League")

    Team.create(league: league, name: "Team 1")
    Team.create(league: league, name: "Team 2")
  end

  let(:current_user) { User.find_by_email("john@example.com") }
  let(:other_user)   { User.find_by_email("mike@example.com") }
  let(:yet_another_user)   { User.find_by_email("peter@example.com") }
  let(:league)   { League.first }
  let(:t1)       { Team.first }
  let(:t2)       { Team.last }

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
      describe "recent matches" do
        it "returns all relevant match information" do
          match = Match.create(
            user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
            user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
          )

          expect(match.api_json).to eq({
                                         "id" => match.id,
                                         "date" => match.created_at.to_i,
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

      describe "versus" do
        it "foo" do
          Match.create!(
            user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
            user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
          )

          Match.create!(
            user1_id: yet_another_user.id, user1_team_id: t1.id, user1_goals: 2,
            user2_id: current_user.id, user2_team_id: t2.id, user2_goals: 0
          )

          Match.create!(
            user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 1,
            user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
          )

          get :stats

          expect(json_response["versus"]).to eq([
                                                  {
                                                    "rivalName" => other_user.name,
                                                    "won" => 1,
                                                    "tied" => 1,
                                                    "lost" => 0,
                                                    "goalsMade" => 4,
                                                    "goalsReceived" => 2,
                                                  },
                                                  {
                                                    "rivalName" => yet_another_user.name,
                                                    "won" => 0,
                                                    "tied" => 0,
                                                    "lost" => 1,
                                                    "goalsMade" => 0,
                                                    "goalsReceived" => 2,
                                                  },
                                                ])
        end
      end
    end

    describe "users" do
      describe "user format" do
        it "includes name and id" do
          expect(current_user.api_json).to eq({
            "id" => current_user.id,
            "name" => current_user.name
          })
        end
      end

      it "returns all users" do
        get :users
        expect(json_response).to eq([current_user.api_json, other_user.api_json, yet_another_user.api_json])
      end
    end

    describe "leagues" do
      describe "league format" do
        it "includes name and id" do
          expect(league.api_json).to eq({
            "id" => league.id,
            "name" => league.name
          })
        end
      end

      it "returns all leagues with their names and ids" do
        get :leagues
        expect(json_response).to eq([league.api_json])
      end

      describe "league_teams" do
        it "returns a league's teams" do
          get :league_teams, params: { id: league.id }
          expect(json_response).to eq([t1.api_json, t2.api_json])
        end
      end
    end

    describe "recent teams" do
      it "returns empty array if user has no matches" do
        get :recent_teams, params: { id: current_user.id }
        expect(json_response).to eq([])
      end

      it "returns the last used teams order by last used date" do
        Match.create!(
          user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
          user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
        )

        Match.create!(
          user1_id: other_user.id, user1_team_id: t1.id, user1_goals: 2,
          user2_id: current_user.id, user2_team_id: t2.id, user2_goals: 0
        )

        get :recent_teams, params: { id: current_user.id }
        expect(json_response).to eq([t2.api_json, t1.api_json])

        Match.create!(
          user1_id: current_user.id, user1_team_id: t1.id, user1_goals: 3,
          user2_id: other_user.id, user2_team_id: t2.id, user2_goals: 1
        )

        get :recent_teams, params: { id: current_user.id }
        expect(json_response).to eq([t1.api_json, t2.api_json])
      end
    end

    describe "reporting matches" do
      it "created a new record in the database" do
        expect {
          post :report_match, params: {
                 rival_id: other_user.id,
                 own_goals: 1,
                 rival_goals: 2,
                 own_team_id: t1.id,
                 rival_team_id: t2.id
               }
        }.to change { Match.count }.from(0).to(1)

        expect(response.code).to eq("204")
        expect(response.body).to be_empty

        match = Match.first

        expect(match.user1_id).to eq(current_user.id)
        expect(match.user2_id).to eq(other_user.id)
        expect(match.user1_goals).to eq(1)
        expect(match.user2_goals).to eq(2)
        expect(match.team1.id).to eq(t1.id)
        expect(match.team2.id).to eq(t2.id)
      end

      it "fails if both user ids match" do
        post :report_match, params: {
               rival_id: current_user.id,
               own_goals: 1,
               rival_goals: 2,
               own_team_id: t1.id,
               rival_team_id: t2.id
             }

        expect(response.code).to eq("400")
        expect(Match.count).to eq(0)
      end

      it "fails if a negative amount of goals is reported" do
        post :report_match, params: {
               rival_id: other_user.id,
               own_goals: -1,
               rival_goals: 2,
               own_team_id: t1.id,
               rival_team_id: t2.id
             }
        expect(response.code).to eq("400")
        expect(Match.count).to eq(0)

        post :report_match, params: {
                rival_id: other_user.id,
                own_goals: 1,
                rival_goals: -2,
                own_team_id: t1.id,
                rival_team_id: t2.id
              }
        expect(response.code).to eq("400")
        expect(Match.count).to eq(0)
      end
    end
  end


  def json_response
    JSON.parse(response.body)
  end
end
