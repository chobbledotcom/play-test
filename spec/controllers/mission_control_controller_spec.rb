# frozen_string_literal: true

require "rails_helper"

RSpec.describe MissionControlController, type: :controller do
  describe "authentication" do
    it "inherits from ApplicationController" do
      expect(described_class).to be < ApplicationController
    end

    it "requires admin authentication" do
      # Get the before_action callbacks
      callbacks = described_class._process_action_callbacks
      before_actions = callbacks.select { |cb| cb.kind == :before }
      
      # Check that require_admin is in the callback chain
      require_admin_callback = before_actions.find { |cb| cb.filter == :require_admin }
      expect(require_admin_callback).not_to be_nil
    end
  end
end