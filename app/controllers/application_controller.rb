class ApplicationController < ActionController::Base

  protect_from_forgery with: :exception
  before_action :check_user, only: :index

  def index
    @js_flags = {
      "user" => {
        "id" => @current_user.id,
        "name" => @current_user.name
      }
    }
  end

  def check_user
    unless session[:user_id] && User.exists?(session[:user_id])
      redirect_to login_start_path
      return false
    end

    set_current_user
  end

  def set_current_user
    @current_user = User.find(session[:user_id])

    unless @current_user
      raise "Internal Error"
    end
  end
end
