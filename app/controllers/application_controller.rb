class ApplicationController < ActionController::Base

  before_action :authenticate_web, only: :index

  def index
    @js_flags = {
      "user" => {
        "id" => @current_user.id,
        "name" => @current_user.name
      }
    }
  end

  def authenticate_web
    user = load_current_user

    if user
      @current_user = user
    else
      redirect_to login_start_path
      return false
    end
  end

  def authenticate_api
    user = load_current_user

    if user
      @current_user = user
    else
      head 401
      return false
    end
  end

  def load_current_user
    user_id = cookies.encrypted[:fifatum_data]
    user_id ? User.find_by(id: user_id) : nil
  end
end
