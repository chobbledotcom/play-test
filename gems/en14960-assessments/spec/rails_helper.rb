# typed: false
# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "spec_helper"
require "rails"
require "active_record"
require "en14960_assessments"

ActiveRecord::Base.establish_connection(
  adapter: "sqlite3",
  database: ":memory:"
)
