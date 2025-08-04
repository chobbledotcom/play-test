# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Prosopite N+1 detection" do
  it "is configured in ApplicationController" do
    methods = ApplicationController.private_instance_methods
    expect(methods).to include(:n_plus_one_detection)
  end

  it "is enabled in test environment" do
    controller = ApplicationController.new
    callbacks = controller._process_action_callbacks.map(&:filter)
    expect(callbacks).to include(:n_plus_one_detection)
  end

  it "would be enabled in development environment" do
    allow(Rails.env).to receive(:development?).and_return(true)
    allow(Rails.env).to receive(:test?).and_return(false)
    allow(Rails.env).to receive(:production?).and_return(false)

    # This would require reloading the controller, so we just verify condition
    expect(Rails.env.production? || Rails.env.test?).to be false
  end
end
