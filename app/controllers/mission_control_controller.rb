# frozen_string_literal: true

class MissionControlController < ApplicationController
  before_action :require_admin
end