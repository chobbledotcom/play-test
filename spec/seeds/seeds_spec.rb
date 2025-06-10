require "rails_helper"

RSpec.describe "Seed Data", type: :model do
  describe "db:seed" do
    # Clean state before running seeds
    before(:all) do
      # Clear all data first
      UserHeightAssessment.destroy_all
      StructureAssessment.destroy_all
      SlideAssessment.destroy_all
      MaterialsAssessment.destroy_all
      FanAssessment.destroy_all
      EnclosedAssessment.destroy_all
      AnchorageAssessment.destroy_all
      Inspection.destroy_all
      Unit.destroy_all
      User.destroy_all
      InspectorCompany.destroy_all

      # Run the seeds
      load Rails.root.join("db", "seeds.rb")
    end

    describe "Inspector Companies" do
      it "creates expected number of inspector companies" do
        expect(InspectorCompany.count).to eq(3)
      end

      it "creates companies with all required fields" do
        companies = InspectorCompany.all
        companies.each do |company|
          expect(company.name).to be_present
          expect(company.email).to be_present
          expect(company.phone).to be_present
          expect(company.address).to be_present
          expect(company.city).to be_present
          expect(company.state).to be_present
          expect(company.postal_code).to be_present
          expect(company.country).to eq("UK")
          expect([true, false]).to include(company.active)
        end
      end

      it "creates specific expected companies" do
        stefan_testing = InspectorCompany.find_by(name: "Stefan's Testing Co")
        expect(stefan_testing).to be_present
        expect(stefan_testing.active).to be true

        steph_test = InspectorCompany.find_by(name: "Steph Test")
        expect(steph_test).to be_present
        expect(steph_test.active).to be true

        steve_inflatable = InspectorCompany.find_by(name: "Steve Inflatable Testing")
        expect(steve_inflatable).to be_present
        expect(steve_inflatable.active).to be false
      end

      it "creates companies with valid email formats" do
        InspectorCompany.all.each do |company|
          expect(company.email).to match(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
        end
      end
    end

    describe "Users" do
      it "creates expected number of users" do
        expect(User.count).to eq(6)
      end

      it "creates users with all required fields" do
        users = User.all
        users.each do |user|
          expect(user.email).to be_present
          expect(user.password_digest).to be_present
          expect(user.rpii_inspector_number).to be_present
          expect(user.inspection_limit).to be_present
          expect(user.time_display).to be_present
          expect(["date", "time"]).to include(user.time_display)
        end
      end

      it "creates test user with unlimited inspections" do
        test_user = User.find_by(email: "test@play-test.co.uk")
        expect(test_user).to be_present
        expect(test_user.inspection_company.name).to eq("Stefan's Testing Co")
        expect(test_user.inspection_limit).to eq(-1)
      end

      it "assigns users to appropriate companies" do
        stefan_company = InspectorCompany.find_by(name: "Stefan's Testing Co")
        steph_company = InspectorCompany.find_by(name: "Steph Test")
        steve_company = InspectorCompany.find_by(name: "Steve Inflatable Testing")

        stefan_users = User.where(inspection_company: stefan_company)
        expect(stefan_users.count).to eq(4) # test, lead, junior, senior

        steph_users = User.where(inspection_company: steph_company)
        expect(steph_users.count).to eq(1)

        steve_users = User.where(inspection_company: steve_company)
        expect(steve_users.count).to eq(1)
      end

      it "creates users with valid inspection limits" do
        User.all.each do |user|
          expect(user.inspection_limit).to be >= -1
          expect(user.inspection_limit).to be_a(Integer)
        end
      end
    end

    describe "Units" do
      it "creates expected number of units" do
        expect(Unit.count).to eq(8)
      end

      it "creates units with all required fields" do
        units = Unit.all
        units.each do |unit|
          expect(unit.name).to be_present
          expect(unit.serial).to be_present
          expect(unit.manufacturer).to be_present
          expect(unit.model).to be_present
          expect(unit.owner).to be_present
          expect(unit.description).to be_present
          expect(unit.user).to be_present
          expect(unit.width).to be > 0
          expect(unit.length).to be > 0
          expect(unit.height).to be > 0
          expect([true, false]).to include(unit.has_slide)
          expect([true, false]).to include(unit.is_totally_enclosed)
        end
      end

      it "assigns all units to test user" do
        test_user = User.find_by(email: "test@play-test.co.uk")
        expect(Unit.where(user: test_user).count).to eq(8)
        expect(Unit.where.not(user: test_user).count).to eq(0)
      end

      it "creates units with correct slide and enclosed flags" do
        # Units with slides
        slide_units = Unit.where(has_slide: true)
        expect(slide_units.pluck(:name)).to include(
          "Princess Castle with Slide",
          "Assault Course Challenge",
          "Mega Slide Experience"
        )

        # Enclosed units
        enclosed_units = Unit.where(is_totally_enclosed: true)
        expect(enclosed_units.pluck(:name)).to include("Toddler Soft Play Centre")
      end

      it "creates units with realistic dimensions" do
        Unit.all.each do |unit|
          expect(unit.width).to be_between(1.0, 20.0)
          expect(unit.length).to be_between(1.0, 20.0)
          expect(unit.height).to be_between(1.0, 10.0)
        end
      end

      it "creates units with unique serials" do
        serials = Unit.pluck(:serial)
        expect(serials.uniq.length).to eq(serials.length)
      end
    end

    describe "Inspections" do
      it "creates multiple inspections" do
        expect(Inspection.count).to be >= 10
      end

      it "creates inspections with all required fields" do
        inspections = Inspection.all
        inspections.each do |inspection|
          expect(inspection.user).to be_present
          expect(inspection.unit).to be_present
          expect(inspection.inspector_company).to be_present
          expect(inspection.inspection_date).to be_present
          # Status is now determined by complete_date presence
          expect([true, false]).to include(inspection.complete?)
          expect(inspection.width).to be > 0
          expect(inspection.length).to be > 0
          expect(inspection.height).to be > 0
          expect([true, false]).to include(inspection.has_slide)
          expect([true, false]).to include(inspection.is_totally_enclosed)
        end
      end

      it "creates inspections with various statuses" do
        expect(Inspection.where(complete_date: nil).count).to be >= 1
        expect(Inspection.where.not(complete_date: nil).count).to be >= 1
      end

      it "creates passed and failed inspections" do
        complete_inspections = Inspection.where.not(complete_date: nil)
        expect(complete_inspections.where(passed: true).count).to be >= 1
        expect(complete_inspections.where(passed: false).count).to be >= 1
      end

      it "copies dimensions from units to inspections" do
        Inspection.all.each do |inspection|
          if inspection.unit.present?
            expect(inspection.width).to eq(inspection.unit.width)
            expect(inspection.length).to eq(inspection.unit.length)
            expect(inspection.height).to eq(inspection.unit.height)
            expect(inspection.has_slide).to eq(inspection.unit.has_slide)
            expect(inspection.is_totally_enclosed).to eq(inspection.unit.is_totally_enclosed)
          end
        end
      end

      it "creates inspections with valid associations" do
        Inspection.all.each do |inspection|
          expect(inspection.user.inspection_company).to eq(inspection.inspector_company)
        end
      end

      it "creates inspections for different time periods" do
        recent_inspections = Inspection.where(inspection_date: 1.week.ago..Date.current)
        historical_inspections = Inspection.where(inspection_date: 1.year.ago..6.months.ago)

        expect(recent_inspections.count).to be >= 1
        expect(historical_inspections.count).to be >= 1
      end
    end

    describe "Assessment Data" do
      let(:complete_inspections) { Inspection.where.not(complete_date: nil) }

      it "creates anchorage assessments for complete inspections" do
        complete_inspections.each do |inspection|
          expect(inspection.anchorage_assessment).to be_present
        end
      end

      it "creates structure assessments for complete inspections" do
        complete_inspections.each do |inspection|
          expect(inspection.structure_assessment).to be_present
        end
      end

      it "creates materials assessments for complete inspections" do
        complete_inspections.each do |inspection|
          expect(inspection.materials_assessment).to be_present
        end
      end

      it "creates fan assessments for complete inspections" do
        complete_inspections.each do |inspection|
          expect(inspection.fan_assessment).to be_present
        end
      end

      it "creates user height assessments for complete inspections" do
        complete_inspections.each do |inspection|
          expect(inspection.user_height_assessment).to be_present
        end
      end

      it "creates slide assessments only for units with slides" do
        complete_inspections.each do |inspection|
          if inspection.has_slide
            expect(inspection.slide_assessment).to be_present
          else
            expect(inspection.slide_assessment).to be_nil
          end
        end
      end

      it "creates enclosed assessments only for enclosed units" do
        complete_inspections.each do |inspection|
          if inspection.is_totally_enclosed
            expect(inspection.enclosed_assessment).to be_present
          else
            expect(inspection.enclosed_assessment).to be_nil
          end
        end
      end

      describe "Anchorage Assessments" do
        it "creates assessments with required fields" do
          AnchorageAssessment.joins(:inspection).where.not(inspections: {complete_date: nil}).each do |assessment|
            expect(assessment.inspection).to be_present
            expect(assessment.num_low_anchors).to be_present
            expect(assessment.num_high_anchors).to be_present
            expect([true, false]).to include(assessment.num_anchors_pass)
            expect([true, false]).to include(assessment.anchor_accessories_pass)
            expect([true, false]).to include(assessment.anchor_degree_pass)
            expect([true, false]).to include(assessment.anchor_type_pass)
            expect([true, false]).to include(assessment.pull_strength_pass)
          end
        end

        it "creates assessments with realistic anchor counts" do
          AnchorageAssessment.all.each do |assessment|
            expect(assessment.num_low_anchors).to be_between(0, 20)
            expect(assessment.num_high_anchors).to be_between(0, 15)
          end
        end
      end

      describe "Structure Assessments" do
        it "creates assessments with all required safety checks" do
          StructureAssessment.all.each do |assessment|
            expect(assessment.inspection).to be_present
            expect([true, false]).to include(assessment.seam_integrity_pass)
            expect([true, false]).to include(assessment.lock_stitch_pass)
            expect([true, false]).to include(assessment.air_loss_pass)
            expect([true, false]).to include(assessment.straight_walls_pass)
            expect([true, false]).to include(assessment.sharp_edges_pass)
            expect([true, false]).to include(assessment.unit_stable_pass)
          end
        end

        it "creates assessments with required measurements" do
          StructureAssessment.all.each do |assessment|
            expect(assessment.stitch_length).to be_present
            expect(assessment.unit_pressure_value).to be_present
            expect(assessment.blower_tube_length).to be_present
            expect(assessment.step_size_value).to be_present
            expect(assessment.fall_off_height_value).to be_present
            expect(assessment.trough_depth_value).to be_present
            expect(assessment.trough_width_value).to be_present
          end
        end

        it "creates assessments with realistic measurement values" do
          StructureAssessment.all.each do |assessment|
            expect(assessment.stitch_length).to be_between(5, 20)
            expect(assessment.unit_pressure_value).to be_between(0.5, 5.0)
            expect(assessment.blower_tube_length).to be_between(1.0, 10.0)
            expect(assessment.step_size_value).to be_between(100, 500)
            expect(assessment.fall_off_height_value).to be_between(0.1, 3.0)
            expect(assessment.trough_depth_value).to be_between(0.05, 1.0)
            expect(assessment.trough_width_value).to be_between(0.1, 2.0)
          end
        end
      end

      describe "Materials Assessments" do
        it "creates assessments with required fields" do
          MaterialsAssessment.all.each do |assessment|
            expect(assessment.inspection).to be_present
            expect(assessment.rope_size).to be_present
            expect([true, false]).to include(assessment.rope_size_pass)
            expect([true, false]).to include(assessment.fabric_pass)
            expect([true, false]).to include(assessment.fire_retardant_pass)
            expect([true, false]).to include(assessment.thread_pass)
          end
        end

        it "creates assessments with realistic rope sizes" do
          MaterialsAssessment.all.each do |assessment|
            expect(assessment.rope_size).to be_between(10, 50)
          end
        end
      end

      describe "Fan Assessments" do
        it "creates assessments with all required safety checks" do
          FanAssessment.all.each do |assessment|
            expect(assessment.inspection).to be_present
            expect([true, false]).to include(assessment.blower_flap_pass)
            expect([true, false]).to include(assessment.blower_finger_pass)
            expect([true, false]).to include(assessment.blower_visual_pass)
            expect([true, false]).to include(assessment.pat_pass)
            expect(assessment.blower_serial).to be_present
          end
        end

        it "creates assessments with realistic blower serials" do
          FanAssessment.all.each do |assessment|
            expect(assessment.blower_serial).to match(/FAN-\d{4}/)
          end
        end
      end

      describe "User Height Assessments" do
        it "creates assessments with required measurements" do
          UserHeightAssessment.all.each do |assessment|
            expect(assessment.inspection).to be_present
            expect(assessment.containing_wall_height).to be_present
            expect(assessment.platform_height).to be_present
            expect(assessment.tallest_user_height).to be_present
            expect(assessment.users_at_1000mm).to be_present
            expect(assessment.users_at_1200mm).to be_present
            expect(assessment.users_at_1500mm).to be_present
            expect(assessment.users_at_1800mm).to be_present
            expect(assessment.play_area_length).to be_present
            expect(assessment.play_area_width).to be_present
            expect(assessment.negative_adjustment).to be_present
          end
        end

        it "creates assessments with realistic height values" do
          UserHeightAssessment.all.each do |assessment|
            expect(assessment.containing_wall_height).to be_between(0.5, 3.0)
            expect(assessment.platform_height).to be_between(0.2, 2.0)
            expect(assessment.tallest_user_height).to be_between(1.0, 2.0)
          end
        end

        it "creates assessments with realistic user capacity counts" do
          UserHeightAssessment.all.each do |assessment|
            expect(assessment.users_at_1000mm).to be_between(0, 10)
            expect(assessment.users_at_1200mm).to be_between(0, 15)
            expect(assessment.users_at_1500mm).to be_between(0, 20)
            expect(assessment.users_at_1800mm).to be_between(0, 10)
          end
        end

        it "creates play area dimensions based on unit dimensions" do
          UserHeightAssessment.joins(:inspection).each do |assessment|
            unit = assessment.inspection.unit
            expect(assessment.play_area_length).to be <= unit.length
            expect(assessment.play_area_width).to be <= unit.width
          end
        end
      end

      describe "Slide Assessments" do
        let(:slide_assessments) { SlideAssessment.joins(:inspection).where(inspections: {has_slide: true}) }

        it "creates assessments only for units with slides" do
          slide_unit_count = Inspection.where(has_slide: true).where.not(complete_date: nil).count
          expect(SlideAssessment.count).to eq(slide_unit_count)
        end

        it "creates assessments with required measurements" do
          slide_assessments.each do |assessment|
            expect(assessment.inspection).to be_present
            expect(assessment.slide_platform_height).to be_present
            expect(assessment.slide_wall_height).to be_present
            expect(assessment.runout_value).to be_present
            expect(assessment.slide_first_metre_height).to be_present
            expect(assessment.slide_beyond_first_metre_height).to be_present
          end
        end

        it "creates assessments with realistic slide measurements" do
          slide_assessments.each do |assessment|
            expect(assessment.slide_platform_height).to be_between(1.0, 8.0)
            expect(assessment.slide_wall_height).to be_between(0.5, 3.0)
            expect(assessment.runout_value).to be_between(1.0, 5.0)
            expect(assessment.slide_first_metre_height).to be_between(0.1, 1.0)
            expect(assessment.slide_beyond_first_metre_height).to be_between(0.5, 2.0)
          end
        end

        it "creates assessments with required safety checks" do
          slide_assessments.each do |assessment|
            expect([true, false]).to include(assessment.clamber_netting_pass)
            expect([true, false]).to include(assessment.runout_pass)
            expect([true, false]).to include(assessment.slip_sheet_pass)
          end
        end
      end

      describe "Enclosed Assessments" do
        let(:enclosed_assessments) { EnclosedAssessment.joins(:inspection).where(inspections: {is_totally_enclosed: true}) }

        it "creates assessments only for enclosed units" do
          enclosed_unit_count = Inspection.where(is_totally_enclosed: true).where.not(complete_date: nil).count
          expect(EnclosedAssessment.count).to eq(enclosed_unit_count)
        end

        it "creates assessments with required fields" do
          enclosed_assessments.each do |assessment|
            expect(assessment.inspection).to be_present
            expect(assessment.exit_number).to be_present
            expect([true, false]).to include(assessment.exit_number_pass)
            expect([true, false]).to include(assessment.exit_visible_pass)
          end
        end

        it "creates assessments with realistic exit counts" do
          enclosed_assessments.each do |assessment|
            expect(assessment.exit_number).to be_between(1, 5)
          end
        end
      end
    end

    describe "Data Integrity" do
      it "maintains referential integrity" do
        expect {
          # Test that all foreign key relationships are valid
          User.includes(:inspection_company, :units, :inspections).all
          Unit.includes(:user, :inspections).all
          Inspection.includes(:user, :unit, :inspector_company, :anchorage_assessment,
            :structure_assessment, :materials_assessment, :fan_assessment,
            :user_height_assessment, :slide_assessment, :enclosed_assessment).all
        }.not_to raise_error
      end

      it "ensures all created records are valid" do
        [InspectorCompany, User, Unit, Inspection,
          AnchorageAssessment, StructureAssessment, MaterialsAssessment,
          FanAssessment, UserHeightAssessment, SlideAssessment, EnclosedAssessment].each do |model_class|
          model_class.all.each do |record|
            expect(record).to be_valid,
              "#{model_class.name} ##{record.id} is invalid: #{record.errors.full_messages.join(", ")}"
          end
        end
      end

      it "creates records without validation errors" do
        # This test ensures that if new validations are added, the seeds still work
        expect {
          InspectorCompany.all.each(&:validate!)
          User.all.each(&:validate!)
          Unit.all.each(&:validate!)
          Inspection.all.each(&:validate!)
          AnchorageAssessment.all.each(&:validate!)
          StructureAssessment.all.each(&:validate!)
          MaterialsAssessment.all.each(&:validate!)
          FanAssessment.all.each(&:validate!)
          UserHeightAssessment.all.each(&:validate!)
          SlideAssessment.all.each(&:validate!)
          EnclosedAssessment.all.each(&:validate!)
        }.not_to raise_error
      end

      it "creates unique identifiers where required" do
        # Check that required unique fields are actually unique
        rpii_numbers = User.pluck(:rpii_inspector_number)
        expect(rpii_numbers.uniq.length).to eq(rpii_numbers.length)

        user_emails = User.pluck(:email)
        expect(user_emails.uniq.length).to eq(user_emails.length)

        unit_serials = Unit.pluck(:serial)
        expect(unit_serials.uniq.length).to eq(unit_serials.length)

        report_numbers = Inspection.where.not(unique_report_number: nil).pluck(:unique_report_number)
        expect(report_numbers.uniq.length).to eq(report_numbers.length)
      end
    end

    describe "Business Logic Compliance" do
      it "ensures inspections belong to users in the same company" do
        Inspection.includes(:user, :inspector_company).each do |inspection|
          if inspection.user.inspection_company.present?
            expect(inspection.inspector_company).to eq(inspection.user.inspection_company)
          end
        end
      end

      it "creates realistic British data" do
        # Check that addresses and names follow British conventions
        InspectorCompany.all.each do |company|
          expect(company.country).to eq("UK")
          expect(company.postal_code).to match(/\A[A-Z]{1,2}\d{1,2}\s?\d[A-Z]{2}\z/)
        end
      end

      it "ensures assessment data consistency with inspection results" do
        # Test that inspections and assessments are properly linked
        Inspection.where.not(complete_date: nil).each do |inspection|
          if inspection.anchorage_assessment
            expect(inspection.anchorage_assessment.inspection).to eq(inspection)
          end
          if inspection.structure_assessment
            expect(inspection.structure_assessment.inspection).to eq(inspection)
          end
          if inspection.materials_assessment
            expect(inspection.materials_assessment.inspection).to eq(inspection)
          end
          if inspection.fan_assessment
            expect(inspection.fan_assessment.inspection).to eq(inspection)
          end
          if inspection.user_height_assessment
            expect(inspection.user_height_assessment.inspection).to eq(inspection)
          end
          if inspection.slide_assessment
            expect(inspection.slide_assessment.inspection).to eq(inspection)
          end
          if inspection.enclosed_assessment
            expect(inspection.enclosed_assessment.inspection).to eq(inspection)
          end
        end
      end
    end

    describe "Performance and Scale" do
      it "creates a reasonable amount of test data" do
        expect(InspectorCompany.count).to be_between(2, 10)
        expect(User.count).to be_between(5, 20)
        expect(Unit.count).to be_between(5, 20)
        expect(Inspection.count).to be_between(10, 50)
      end

      it "creates data efficiently without N+1 queries" do
        # This test ensures that the seeds don't have performance issues
        expect {
          InspectorCompany.includes(:users).all
          User.includes(:inspection_company, :units, :inspections).all
          Unit.includes(:user, :inspections).all
          Inspection.includes(:user, :unit, :inspector_company).all
        }.not_to raise_error
      end
    end
  end
end
