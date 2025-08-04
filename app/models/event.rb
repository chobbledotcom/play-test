# frozen_string_literal: true

class Event < ChobbleApp::Event
  # Override the user association to use the app's User class
  belongs_to :user, class_name: "User"
end
