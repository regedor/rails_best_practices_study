class ApplicationController < ActionController::Base
  protect_from_forgery
  helper_method :is_admin?
  def is_admin?
    Rails.env == "development"
  end
end
