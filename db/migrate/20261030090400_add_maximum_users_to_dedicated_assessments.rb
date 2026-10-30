# typed: true
# frozen_string_literal: true

class AddMaximumUsersToDedicatedAssessments < ActiveRecord::Migration[8.1]
  extend T::Sig

  sig { void }
  def change
    %i[
      ball_pool_assessments
      bungee_assessments
      catch_bed_assessments
      inflatable_game_assessments
    ].each do |table|
      add_column table, :maximum_users, :integer
    end
  end
end
