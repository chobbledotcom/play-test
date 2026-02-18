# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: slide_assessments
#
#  clamber_netting_comment                 :text
#  clamber_netting_pass                    :integer
#  runout                                  :decimal(8, 2)
#  runout_comment                          :text
#  runout_pass                             :boolean
#  slide_beyond_first_metre_height         :decimal(8, 2)
#  slide_beyond_first_metre_height_comment :text
#  slide_first_metre_height                :decimal(8, 2)
#  slide_first_metre_height_comment        :text
#  slide_permanent_roof                    :boolean
#  slide_permanent_roof_comment            :text
#  slide_platform_height                   :decimal(8, 2)
#  slide_platform_height_comment           :text
#  slide_wall_height                       :decimal(8, 2)
#  slide_wall_height_comment               :text
#  slip_sheet_comment                      :text
#  slip_sheet_pass                         :boolean
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  inspection_id                           :string(12)       not null, primary key
#
# Indexes
#
#  slide_assessments_new_pkey  (inspection_id) UNIQUE
#
# Foreign Keys
#
#  inspection_id  (inspection_id => inspections.id)
#
require "rails_helper"

RSpec.describe Assessments::SlideAssessment, type: :model do
  let(:inspection) { create(:inspection) }
  let(:slide_assessment) { inspection.slide_assessment }

  describe "associations" do
    it "belongs to inspection" do
      expect(slide_assessment.inspection).to eq(inspection)
    end
  end

  describe "enums" do
    it "defines clamber_netting_pass enum with PASS_FAIL_NA values" do
      expect(described_class.clamber_netting_passes).to eq(
        "fail" => 0,
        "pass" => 1,
        "na" => 2
      )
    end
  end

  describe "#meets_runout_requirements?" do
    context "when runout is nil" do
      before do
        slide_assessment.update(
          runout: nil,
          slide_platform_height: 2.0
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_runout_requirements?).to be false
      end
    end

    context "when slide_platform_height is nil" do
      before do
        slide_assessment.update(
          runout: 3.0,
          slide_platform_height: nil
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_runout_requirements?).to be false
      end
    end

    context "when both runout and slide_platform_height are nil" do
      before do
        slide_assessment.update(
          runout: nil,
          slide_platform_height: nil
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_runout_requirements?).to be false
      end
    end

    context "when both values are present" do
      context "when requirements are met" do
        before do
          slide_assessment.update(
            runout: 2.0,
            slide_platform_height: 2.0
          )
          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_runout_requirements?)
            .with(2.0, 2.0)
            .and_return(true)
        end

        it "returns true" do
          expect(slide_assessment.meets_runout_requirements?).to be true
        end

        it "calls SlideCalculator with correct parameters" do
          expect(EN14960::Calculators::SlideCalculator).to receive(:meets_runout_requirements?)
            .with(2.0, 2.0)
          slide_assessment.meets_runout_requirements?
        end
      end

      context "when requirements are not met" do
        before do
          slide_assessment.update(
            runout: 0.5,
            slide_platform_height: 3.0
          )
          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_runout_requirements?)
            .with(0.5, 3.0)
            .and_return(false)
        end

        it "returns false" do
          expect(slide_assessment.meets_runout_requirements?).to be false
        end
      end
    end

    context "when values are zero" do
      before do
        slide_assessment.update(
          runout: 0.0,
          slide_platform_height: 0.0
        )
        allow(EN14960::Calculators::SlideCalculator).to receive(:meets_runout_requirements?)
          .with(0.0, 0.0)
          .and_return(false)
      end

      it "still calls calculator (present? returns true for 0.0)" do
        expect(slide_assessment.meets_runout_requirements?).to be false
      end
    end
  end

  describe "#required_runout_length" do
    context "when slide_platform_height is nil" do
      before do
        slide_assessment.update(slide_platform_height: nil)
      end

      it "returns nil" do
        expect(slide_assessment.required_runout_length).to be_nil
      end
    end

    context "when slide_platform_height is zero" do
      before do
        slide_assessment.update(slide_platform_height: 0.0)
        allow(EN14960::Calculators::SlideCalculator).to receive(:calculate_runout_value)
          .with(0.0)
          .and_return(0)
      end

      it "still calls calculator (blank? returns false for 0.0)" do
        expect(slide_assessment.required_runout_length).to eq(0)
      end
    end

    context "when slide_platform_height is present" do
      before do
        slide_assessment.update(slide_platform_height: 2.5)
        allow(EN14960::Calculators::SlideCalculator).to receive(:calculate_runout_value)
          .with(2.5)
          .and_return(125)
      end

      it "returns the calculated runout value" do
        expect(slide_assessment.required_runout_length).to eq(125)
      end

      it "calls SlideCalculator with correct parameter" do
        expect(EN14960::Calculators::SlideCalculator).to receive(:calculate_runout_value)
          .with(2.5)
        slide_assessment.required_runout_length
      end
    end

    context "when slide_platform_height is a negative value" do
      before do
        slide_assessment.update(slide_platform_height: -1.5)
        allow(EN14960::Calculators::SlideCalculator).to receive(:calculate_runout_value)
          .with(-1.5)
          .and_return(0)
      end

      it "still calls the calculator (validation happens elsewhere)" do
        expect(slide_assessment.required_runout_length).to eq(0)
      end
    end
  end

  describe "#meets_wall_height_requirements?" do
    context "when slide_platform_height is nil" do
      before do
        slide_assessment.update(
          slide_platform_height: nil,
          slide_wall_height: 2.0,
          slide_permanent_roof: false
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_wall_height_requirements?).to be false
      end
    end

    context "when slide_wall_height is nil" do
      before do
        slide_assessment.update(
          slide_platform_height: 2.0,
          slide_wall_height: nil,
          slide_permanent_roof: false
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_wall_height_requirements?).to be false
      end
    end

    context "when slide_permanent_roof is nil" do
      before do
        slide_assessment.update(
          slide_platform_height: 2.0,
          slide_wall_height: 2.0,
          slide_permanent_roof: nil
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_wall_height_requirements?).to be false
      end
    end

    context "when all values are nil" do
      before do
        slide_assessment.update(
          slide_platform_height: nil,
          slide_wall_height: nil,
          slide_permanent_roof: nil
        )
      end

      it "returns false" do
        expect(slide_assessment.meets_wall_height_requirements?).to be false
      end
    end

    context "when values are zero" do
      before do
        slide_assessment.update(
          slide_platform_height: 0.0,
          slide_wall_height: 0.0,
          slide_permanent_roof: false
        )
        allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
          .and_return(false)
      end

      it "still calls calculator (present? returns true for 0.0)" do
        expect(slide_assessment.meets_wall_height_requirements?).to be false
      end
    end

    context "when all values are present and valid" do
      context "when requirements are met for all user heights" do
        before do
          slide_assessment.update(
            slide_platform_height: 2.0,
            slide_wall_height: 2.0,
            slide_permanent_roof: false
          )

          [1.0, 1.2, 1.5, 1.8].each do |user_height|
            allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
              .with(2.0, user_height, 2.0, false)
              .and_return(true)
          end
        end

        it "returns true" do
          expect(slide_assessment.meets_wall_height_requirements?).to be true
        end

        it "checks all preset user heights" do
          [1.0, 1.2, 1.5, 1.8].each do |user_height|
            expect(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
              .with(2.0, user_height, 2.0, false)
          end
          slide_assessment.meets_wall_height_requirements?
        end
      end

      context "when requirements are not met for one user height" do
        before do
          slide_assessment.update(
            slide_platform_height: 3.0,
            slide_wall_height: 1.5,
            slide_permanent_roof: false
          )

          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(3.0, 1.0, 1.5, false)
            .and_return(true)
          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(3.0, 1.2, 1.5, false)
            .and_return(true)
          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(3.0, 1.5, 1.5, false)
            .and_return(true)
          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(3.0, 1.8, 1.5, false)
            .and_return(false)
        end

        it "returns false" do
          expect(slide_assessment.meets_wall_height_requirements?).to be false
        end
      end

      context "when requirements fail for first user height" do
        before do
          slide_assessment.update(
            slide_platform_height: 3.0,
            slide_wall_height: 0.5,
            slide_permanent_roof: false
          )

          allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(3.0, 1.0, 0.5, false)
            .and_return(false)
        end

        it "returns false immediately" do
          expect(slide_assessment.meets_wall_height_requirements?).to be false
        end

        it "short-circuits and doesn't check remaining heights" do
          expect(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(3.0, 1.0, 0.5, false)
            .once
          expect(EN14960::Calculators::SlideCalculator).not_to receive(:meets_height_requirements?)
            .with(3.0, 1.2, 0.5, false)

          slide_assessment.meets_wall_height_requirements?
        end
      end

      context "with permanent roof true" do
        before do
          slide_assessment.update(
            slide_platform_height: 2.0,
            slide_wall_height: 1.8,
            slide_permanent_roof: true
          )

          [1.0, 1.2, 1.5, 1.8].each do |user_height|
            allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
              .with(2.0, user_height, 1.8, true)
              .and_return(true)
          end
        end

        it "passes the permanent roof flag correctly" do
          expect(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
            .with(2.0, 1.0, 1.8, true)
          slide_assessment.meets_wall_height_requirements?
        end

        it "returns true when all heights pass" do
          expect(slide_assessment.meets_wall_height_requirements?).to be true
        end
      end
    end

    context "with negative values" do
      before do
        slide_assessment.update(
          slide_platform_height: -2.0,
          slide_wall_height: -1.5,
          slide_permanent_roof: false
        )

        allow(EN14960::Calculators::SlideCalculator).to receive(:meets_height_requirements?)
          .and_return(false)
      end

      it "still processes (validation happens elsewhere)" do
        expect(slide_assessment.meets_wall_height_requirements?).to be false
      end
    end
  end

  describe "included modules" do
    it "includes AssessmentLogging" do
      expect(described_class.ancestors).to include(AssessmentLogging)
    end

    it "includes AssessmentCompletion" do
      expect(described_class.ancestors).to include(AssessmentCompletion)
    end

    it "includes ColumnNameSyms" do
      expect(described_class.ancestors).to include(ColumnNameSyms)
    end

    it "includes FormConfigurable" do
      expect(described_class.ancestors).to include(FormConfigurable)
    end

    it "includes ValidationConfigurable" do
      expect(described_class.ancestors).to include(ValidationConfigurable)
    end
  end

  describe "primary key" do
    it "uses inspection_id as primary key" do
      expect(described_class.primary_key).to eq("inspection_id")
    end
  end
end
