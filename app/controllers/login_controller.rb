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

    user_id = User.find_or_create_by(name: name, email: email).id

    cookies.encrypted[:fifatum_data] = { value: user_id, expires: 1.month.from_now }

    redirect_to root_path
  end

  def logout
    cookies.encrypted[:fifatum_data] = nil
    redirect_to root_path
  end
end
