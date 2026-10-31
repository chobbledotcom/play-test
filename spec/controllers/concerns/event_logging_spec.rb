# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventLogging, type: :controller do
  controller(ApplicationController) do
    include EventLogging
  end

  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "#log_event" do
    it "logs a resource event when a resource is given" do
      expect(Event).to receive(:log).with(
        user: user, action: :update, resource: unit,
        details: nil, changed_data: nil
      )
      controller.send(:log_event, :update, unit, resource_type: :unit)
    end

    it "logs a system event when no resource is given" do
      expect(Event).to receive(:log_system_event).with(
        user: user, action: :update, details: nil,
        metadata: {resource_type: :unit}
      )
      controller.send(:log_event, :update, nil, resource_type: :unit)
    end

    it "logs an error when Event.log raises" do
      allow(Event).to receive(:log).and_raise(StandardError, "boom")
      expect(Rails.logger).to receive(:error)
      expect { controller.send(:log_event, :update, unit, resource_type: :unit) }
        .not_to raise_error
    end

    it "does nothing without a current user" do
      allow(controller).to receive(:current_user).and_return(nil)
      expect(Event).not_to receive(:log)
      expect { controller.send(:log_event, :update, unit, resource_type: :unit) }
        .not_to raise_error
    end
  end
end
