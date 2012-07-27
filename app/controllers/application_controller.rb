class ApplicationController < ActionController::Base
  protect_from_forgery
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  private

    def login_url
      new_user_session_path
    end

    def require_login
      unless user_signed_in?
        store_location
        redirect_to login_url, notice: "You must be logged in to access this page."
      end
    end

    def store_location
      return_to_location = session[:return_to_location] = request.url
    end
end
