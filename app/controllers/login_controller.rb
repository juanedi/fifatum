class LoginController < ActionController::Base
  def start
    if Rails.env.development?
      redirect_to "/auth/developer"
    else
      redirect_to "/auth/google_oauth2"
    end
  end

  def callback
    email = request.env['omniauth.auth']['info']['email']
    name = request.env['omniauth.auth']['info']['name']

    session[:user_id] = User.find_or_create_by(name: name, email: email).id

    redirect_to root_path
  end

  def logout
    session[:user_id] = nil
    redirect_to root_path
  end
end
