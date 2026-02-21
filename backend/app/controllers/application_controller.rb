# frozen_string_literal: true

class ApplicationController < ActionController::API
  include ClerkAuthenticatable
  include ProblemRenderable

  before_action :authenticate_with_clerk!


end
