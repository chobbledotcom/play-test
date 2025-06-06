require "rails_helper"

RSpec.describe PdfGeneratorService do
  describe ".generate_inspection_certificate" do
    let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }
    let(:inspection) do
      Inspection.create!(
        serial: "TEST123",
        location: "Test Location",
        manufacturer: "Test Manufacturer",
        passed: true,
        inspection_date: Date.today,
        reinspection_date: Date.today + 1.year,
        inspector: "Test Inspector",
        user: user
      )
    end

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    context "with comments" do
      before do
        inspection.update(comments: "Test comments")
      end

      it "generates PDF with comments" do
        pdf = PdfGeneratorService.generate_inspection_certificate(inspection)
        expect(pdf).to be_a(Prawn::Document)
      end
    end
  end

  describe ".generate_equipment_certificate" do
    let(:user) { User.create!(email: "test@example.com", password: "password", password_confirmation: "password") }
    let(:equipment) do
      Equipment.create!(
        name: "Test Equipment",
        serial: "EQ123",
        location: "Test Location",
        manufacturer: "Test Manufacturer",
        user: user
      )
    end

    it "generates a PDF" do
      pdf = PdfGeneratorService.generate_equipment_certificate(equipment)
      expect(pdf).to be_a(Prawn::Document)

      pdf_string = pdf.render
      expect(pdf_string).to be_a(String)
      expect(pdf_string[0..3]).to eq("%PDF")
    end

    context "with inspections" do
      before do
        Inspection.create!(
          serial: "TEST123",
          location: "Test Location",
          manufacturer: "Test Manufacturer",
          passed: true,
          inspection_date: Date.today,
          reinspection_date: Date.today + 1.year,
          inspector: "Test Inspector",
          user: user,
          equipment: equipment
        )
      end

      it "generates PDF with inspection history" do
        pdf = PdfGeneratorService.generate_equipment_certificate(equipment)
        expect(pdf).to be_a(Prawn::Document)
      end
    end
  end
end
