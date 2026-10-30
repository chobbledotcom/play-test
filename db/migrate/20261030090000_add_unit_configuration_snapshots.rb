# typed: false
# frozen_string_literal: true

class AddUnitConfigurationSnapshots < ActiveRecord::Migration[8.1]
  COMPONENT_FIELDS = %i[
    has_air_jugglers
    has_ancillary_equipment
    has_ball_pool
    has_blower
    has_containing_walls
    has_fencing
    has_inflatable_bed
    has_slide
    indoor_only
    is_totally_enclosed
  ].freeze

  def change
    COMPONENT_FIELDS.each do |field|
      add_column :units, field, :boolean
    end

    (COMPONENT_FIELDS - %i[has_slide indoor_only is_totally_enclosed]).each do |field|
      add_column :inspections, field, :boolean
    end

    add_column :inspections, :checklist_revision, :integer
    add_column :inspections, :inspection_location, :string
  end
end
