# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Prosopite N+1 detection" do
  it "is configured in ApplicationController" do
    expect(ApplicationController.private_instance_methods).to include(:n_plus_one_detection)
  end

  it "is enabled in test environment" do
    expect(Prosopite.instance_variable_get(:@raise)).to eq(true)
  end

  it "is configured with custom logger" do
    expect(Prosopite.instance_variable_get(:@custom_logger)).not_to be_nil
  end

  it "has allow_stack_paths configured" do
    allow_paths = Prosopite.instance_variable_get(:@allow_stack_paths)
    expect(allow_paths).to include("active_storage")
    expect(allow_paths).to include("active_record/associations/preloader")
  end
end