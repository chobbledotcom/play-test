# typed: true
# frozen_string_literal: true

class AddMeasuredUserLimits < ActiveRecord::Migration[8.1]
  extend T::Sig

  sig { void }
  def change
    add_column :bungee_assessments, :marking_max_mass, :decimal,
      precision: 8, scale: 2
    add_column :bungee_assessments, :marking_min_height, :decimal,
      precision: 8, scale: 2
    add_column :bungee_assessments, :pull_strength, :decimal,
      precision: 10, scale: 2
    add_column :anchorage_assessments, :bungee_side_area, :decimal,
      precision: 10, scale: 4
    add_column :catch_bed_assessments, :max_user_mass_marking, :decimal,
      precision: 8, scale: 2
    add_column :inflatable_game_assessments, :max_user_mass, :decimal,
      precision: 8, scale: 2
    add_column :ball_pool_assessments, :max_height_markings, :decimal,
      precision: 8, scale: 2
    add_column :play_zone_assessments, :height_marking, :decimal,
      precision: 8, scale: 2
    add_column :user_height_assessments, :maximum_user_height, :decimal,
      precision: 8, scale: 2
    add_age_limits
  end

  private

  sig { void }
  def add_age_limits
    %i[ball_pool_assessments inflatable_game_assessments
      play_zone_assessments].each do |table|
      add_column table, :minimum_age, :decimal, precision: 5, scale: 1
      add_column table, :maximum_age, :decimal, precision: 5, scale: 1
    end
  end
end
