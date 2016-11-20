Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "application#index"

  get '/login/start' => 'login#start'
  post '/auth/:provider/callback' => 'login#callback'
  get '/logout' => 'login#logout'

  scope :api do
    get 'ranking', to: 'api#ranking'
    get 'history/user', to: 'api#user_history'
  end

end
