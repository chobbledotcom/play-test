# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe AssessmentGuidance do
  def assessment_for(type, key, components = {})
    unit = create(:unit, unit_type: type, **components)
    inspection = create(:inspection, unit: unit, checklist_revision: 2)
    inspection.public_send(key)
  end

  it "compares ball depth on both sides of the reference without judging it" do
    assessment = assessment_for(:inflatable_ball_pool, :ball_pool_assessment)
    assessment.assign_attributes(ball_pool_depth: 450,
      ball_pool_depth_pass: "fail")
    comparison = described_class.new(assessment).comparisons
      .find { _1[:field] == :ball_pool_depth }
    expect(comparison[:status]).to eq(:within)
    expect(assessment.ball_pool_depth_pass).to eq("fail")

    assessment.ball_pool_depth = 451
    comparison = described_class.new(assessment).comparisons
      .find { _1[:field] == :ball_pool_depth }
    expect(comparison[:status]).to eq(:outside)
    expect(assessment.ball_pool_depth_pass).to eq("fail")
  end

  it "preserves the conditional game wall requirement at 630 mm" do
    assessment = assessment_for(:inflatable_game,
      :inflatable_game_assessment, has_containing_walls: true)
    {"0.63" => :not_triggered, "0.64" => :outside,
     "0.89" => :outside, "0.90" => :within}.each do |height, status|
      assessment.containing_wall_height = height
      comparison = described_class.new(assessment).comparisons
        .find { _1[:field] == :containing_wall_height }
      expect(comparison[:status]).to eq(status)
    end
  end

  it "uses the current 2400 N harness reference, never the old 1200 N" do
    assessment = assessment_for(:bungee_run, :bungee_assessment)
    {2399 => :outside, 2400 => :within, 2401 => :within}.each do |force, status|
      assessment.pull_strength = force
      comparison = described_class.new(assessment).comparisons
        .find { _1[:field] == :pull_strength }
      expect(comparison[:status]).to eq(status)
    end
  end

  it "uses access-gradient and platform-height references independently" do
    assessment = assessment_for(:play_zone, :play_zone_assessment,
      has_slide: true)
    assessment.assign_attributes(slide_gradient: 65,
      slide_platform_height: 1.5)
    comparisons = described_class.new(assessment).comparisons
      .index_by { _1[:field] }
    expect(comparisons[:slide_gradient][:status]).to eq(:outside)
    expect(comparisons[:slide_platform_height][:status]).to eq(:within)
  end

  it "does not compare absent or explicitly N/A measurements" do
    assessment = assessment_for(:bungee_run, :bungee_assessment)
    assessment.assign_attributes(pull_strength: 1200, pull_strength_pass: "na",
      rear_wall_height: 0.1, rear_wall_pass: "na")
    fields = described_class.new(assessment).comparisons.map { _1[:field] }
    expect(fields).not_to include(:pull_strength, :rear_wall_height,
      :marking_max_mass)
  end

  it "does not use hidden game-bed measurements for guidance" do
    assessment = assessment_for(:inflatable_game,
      :inflatable_game_assessment, has_inflatable_bed: false)
    assessment.max_user_mass = 200
    fields = described_class.new(assessment).comparisons.map { _1[:field] }
    expect(fields).not_to include(:max_user_mass)
  end

  it "does not invent numeric game age thresholds" do
    assessment = assessment_for(:inflatable_game, :inflatable_game_assessment)
    assessment.assign_attributes(minimum_age: 7, maximum_age: 90)
    comparisons = described_class.new(assessment).comparisons
      .select { %i[minimum_age maximum_age].include?(_1[:field]) }
    expect(comparisons.map { _1[:status] }).to eq([:recorded, :recorded])
  end

  it "reuses rounded-down user capacity without changing recorded counts" do
    assessment = assessment_for(:bouncy_castle, :user_height_assessment)
    assessment.assign_attributes(play_area_length: 4, play_area_width: 4,
      maximum_user_height: 1.8, negative_adjustment: 1,
      users_at_1000mm: 16, users_at_1200mm: 11)
    comparisons = described_class.new(assessment).comparisons
      .index_by { _1[:field] }
    expect(comparisons[:users_at_1000mm][:reference]).to eq(15)
    expect(comparisons[:users_at_1000mm][:status]).to eq(:outside)
    expect(comparisons[:users_at_1200mm][:reference]).to eq(11)
    expect(comparisons[:users_at_1200mm][:status]).to eq(:within)
    expect(assessment.users_at_1000mm).to eq(16)
  end

  it "does not turn absent adjustment data into successful capacity guidance" do
    assessment = assessment_for(:bouncy_castle, :user_height_assessment)
    assessment.assign_attributes(play_area_length: 4, play_area_width: 4,
      maximum_user_height: 1.8, negative_adjustment: nil,
      users_at_1000mm: 16)
    expect(described_class.new(assessment).comparisons).to be_empty
  end

  it "leaves untouched legacy guidance unchanged" do
    assessment = assessment_for(:bungee_run, :bungee_assessment)
    assessment.inspection.update_column(:checklist_revision, nil)
    assessment.pull_strength = 1200
    expect(described_class.new(assessment).comparisons).to be_empty
  end
end
