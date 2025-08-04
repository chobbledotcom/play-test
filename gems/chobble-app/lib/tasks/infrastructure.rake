# frozen_string_literal: true

namespace :chobble_app do
  desc "Set up infrastructure files (Dockerfile, linters, etc) in the host application"
  task :setup_infrastructure do
    require_relative "../../infrastructure/setup_infrastructure"
    InfrastructureSetup.setup(Rails.root)
  end
end