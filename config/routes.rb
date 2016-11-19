Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "application#index"

  scope :api do
    get 'ranking', to: 'api#ranking'
  end

end
