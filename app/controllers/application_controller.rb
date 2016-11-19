class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :check_user

  def index
    check_user

    @js_flags = {
      "username" => @current_user.name
    }
  end

  def check_user
    unless session[:user_id]
      redirect_to login_start_path
      return false
    end

    @current_user = User.find(session[:user_id])

    unless @current_user
      raise "Internal Error"
    end
  end
end
