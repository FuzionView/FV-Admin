class SystemSettingsController < ApplicationController
  include Pundit::Authorization
  after_action :verify_authorized

  def index
    authorize AccuracyClass # Any domain table model satisfies
  end
end
