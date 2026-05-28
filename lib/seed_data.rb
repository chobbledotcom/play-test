# typed: false
# frozen_string_literal: true

require_relative "seed_data/shared"

module SeedData
  PASS = Shared::PASS
  FAIL = Shared::FAIL
  GOOD = Shared::GOOD
  WEAR = Shared::WEAR
  OK = Shared::OK

  def self.pass_fail_fields(passed, *fields)
    Shared.pass_fail_fields(passed, *fields)
  end

  def self.check_passed?(inspection_passed)
    Shared.check_passed?(inspection_passed)
  end

  def self.check_passed_integer?(inspection_passed)
    Shared.check_passed_integer?(inspection_passed)
  end

  def self.user_fields
    Shared.user_fields
  end

  def self.unit_fields
    Shared.unit_fields
  end

  def self.inspection_fields(passed: true)
    Shared.inspection_fields(passed: passed)
  end

  def self.results_fields(passed: true)
    Shared.results_fields(passed: passed)
  end

  def self.anchorage_fields(passed: true)
    Shared.anchorage_fields(passed: passed)
  end

  def self.user_height_fields(passed: true)
    {
      containing_wall_height: rand(1.0..2.0).round(1),
      users_at_1000mm: rand(0..5),
      users_at_1200mm: rand(2..8),
      users_at_1500mm: rand(4..10),
      users_at_1800mm: rand(2..6),
      custom_user_height_comment: Shared::OK,
      play_area_length: rand(3.0..10.0).round(1),
      play_area_width: rand(3.0..8.0).round(1),
      negative_adjustment: rand(0..2.0).round(1),
      containing_wall_height_comment: Shared::OK,
      play_area_length_comment: Shared::OK,
      play_area_width_comment: Shared::OK
    }
  end

  def self.enclosed_fields(passed: true)
    {
      exit_number: rand(1..3),
      exit_number_pass: Shared.check_passed?(passed),
      exit_sign_always_visible_pass: Shared.check_passed?(passed)
    }.merge(
      Shared.pass_fail_fields(
        passed,
        :exit_number_comment,
        :exit_sign_always_visible_comment
      )
    )
  end

  def self.structure_fields(passed: true)
    Structure.fields(passed: passed)
  end

  def self.structure_pass_fields(passed)
    Structure.pass_fields(passed)
  end

  def self.structure_numeric_fields
    Structure.numeric_fields
  end

  def self.structure_comments(passed)
    Structure.comments(passed)
  end

  def self.materials_fields(passed: true)
    Materials.fields(passed: passed)
  end

  def self.materials_comments(passed)
    Materials.comments(passed)
  end

  def self.fan_fields(passed: true)
    Fan.fields(passed: passed)
  end

  def self.fan_comments(passed)
    Fan.comments(passed)
  end

  def self.slide_fields(passed: true)
    Slide.fields(passed: passed)
  end

  def self.calculate_slide_runout(required_runout, passed)
    Slide.calculate_runout(required_runout, passed)
  end

  def self.slide_comments(passed)
    Slide.comments(passed)
  end

  def self.ball_pool_fields(passed: true)
    BallPool.fields(passed: passed)
  end

  def self.ball_pool_comments(passed)
    BallPool.comments(passed)
  end

  def self.catch_bed_fields(passed: true)
    CatchBed.fields(passed: passed)
  end

  def self.catch_bed_pass_fields(passed)
    CatchBed.pass_fields(passed)
  end

  def self.catch_bed_measurements(passed)
    CatchBed.measurements(passed)
  end

  def self.catch_bed_comments(passed)
    CatchBed.comments(passed)
  end

  def self.bungee_fields(passed: true)
    Bungee.fields(passed: passed)
  end

  def self.bungee_pass_fields(passed)
    Bungee.pass_fields(passed)
  end

  def self.bungee_measurements
    Bungee.measurements
  end

  def self.bungee_comments(passed)
    Bungee.comments(passed)
  end

  def self.inflatable_game_fields(passed: true)
    InflatableGame.fields(passed: passed)
  end

  def self.inflatable_game_comments(passed)
    InflatableGame.comments(passed)
  end

  def self.play_zone_fields(passed: true)
    PlayZone.fields(passed: passed)
  end

  def self.play_zone_pass_fields(passed)
    PlayZone.pass_fields(passed)
  end

  def self.play_zone_measurements(passed)
    PlayZone.measurements(passed)
  end

  def self.play_zone_comments(passed)
    PlayZone.comments(passed)
  end

  def self.pat_fields(passed: true)
    Pat.fields(passed: passed)
  end

  def self.pat_numeric_fields
    Pat.numeric_fields
  end

  def self.pat_pass_fields(passed)
    Pat.pass_fields(passed)
  end

  def self.pat_comments(passed)
    Pat.comments(passed)
  end
end
