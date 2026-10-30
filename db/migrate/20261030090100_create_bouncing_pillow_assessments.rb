# typed: true
# frozen_string_literal: true

class CreateBouncingPillowAssessments < ActiveRecord::Migration[8.1]
  extend T::Sig

  CHECK_FIELDS = %i[
    air_loss_points
    artwork
    clear_area
    deflation_evacuation_time
    depth_of_impact_attenuation
    fabric_fr
    fabric_strength
    fencing_distance
    fencing_entrapment
    fencing_gateways
    fencing_height
    fencing_strength
    fencing_visibility
    foundation
    gradient_average
    grounding
    hard_objects
    headroom
    identification
    internal_pressure
    number_of_users
    security_of_seams
    signage
    slope
  ].freeze

  sig { void }
  def change
    create_table :bouncing_pillow_assessments, id: false do |t|
      t.string :inspection_id, limit: 12, null: false
      add_check_fields(t)
      add_measurements(t)
      t.timestamps
    end
    add_index :bouncing_pillow_assessments, :inspection_id,
      unique: true, name: "bouncing_pillow_assessments_pkey"
    add_foreign_key :bouncing_pillow_assessments, :inspections
  end

  private

  sig { params(table: T.untyped).void }
  def add_check_fields(table)
    CHECK_FIELDS.each do |field|
      table.integer "#{field}_pass"
      table.text "#{field}_comment"
    end
  end

  sig { params(table: T.untyped).void }
  def add_measurements(table)
    table.decimal :gradient_average, precision: 10, scale: 2
    table.decimal :internal_pressure, precision: 10, scale: 2
    table.integer :deflation_evacuation_time
    table.decimal :slope, precision: 10, scale: 2
    table.decimal :clear_area, precision: 10, scale: 2
    table.decimal :depth_of_impact_attenuation, precision: 10, scale: 2
    table.integer :number_of_users
    table.decimal :fencing_distance, precision: 10, scale: 2
    table.decimal :fencing_height, precision: 10, scale: 2
    table.integer :fencing_gateways
  end
end
