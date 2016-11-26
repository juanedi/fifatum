Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "application#index"

  get '/login/start' => 'login#start'
  post '/auth/:provider/callback' => 'login#callback'
  get '/logout' => 'login#logout'

  scope :api do
    get 'users', to: 'api#users'
    get 'users/:id/recent_teams', to: 'api#recent_teams'
    get 'ranking', to: 'api#ranking'
    get 'stats', to: 'api#stats'
    get 'leagues', to: 'api#leagues'
    get 'leagues/:id/teams', to: 'api#league_teams'
    post 'matches', to: 'api#report_match'
  end

end
