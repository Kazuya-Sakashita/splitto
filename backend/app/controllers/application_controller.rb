class ApplicationController < ActionController::API
  include ClerkAuthenticatable

  before_action :authenticate_with_clerk!
end
