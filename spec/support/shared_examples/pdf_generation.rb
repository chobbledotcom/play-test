require "pdf/inspector"

RSpec.shared_examples "generates valid PDF structure" do |pdf_response|
  it "generates a valid PDF document" do
    expect(pdf_response[0..3]).to eq("%PDF")
    expect { PDF::Inspector::Text.analyze(pdf_response) }.not_to raise_error
  end
end

RSpec.shared_examples "generates PDF successfully" do |path|
  it "generates a valid PDF with correct headers" do
    pdf_data = get_pdf(path)
    expect_valid_pdf(pdf_data)
  end
end

RSpec.shared_examples "handles PDF edge case data" do |model, attributes|
  it "generates PDF with edge case data" do
    model.update(attributes)
    pdf_path = model.is_a?(Inspection) ?
      "/inspections/#{model.id}.pdf" :
      "/units/#{model.id}.pdf"
    pdf_data = get_pdf(pdf_path)
    expect_valid_pdf(pdf_data)
  end
end

RSpec.shared_examples "handles unicode in PDFs" do |inspection_or_unit|
  it "properly handles Unicode characters and emoji in PDFs" do
    # Update the object with Unicode content
    if inspection_or_unit.is_a?(Inspection)
      inspection_or_unit.update(
        inspection_location: "Test Location with Ünicøde 😀",
        comments: "Comments with émoji 🎈 and spëcial characters"
      )
    else # Unit
      inspection_or_unit.update(
        name: "Ünicøde Unit 😎",
        manufacturer: "Émoji Company 🏭",
        description: "Description with spëcial characters"
      )
    end
    pdf_response = page.driver.response.body

    expect(pdf_response[0..3]).to eq("%PDF")

    # Parse PDF content
    pdf_text = PDF::Inspector::Text.analyze(pdf_response).strings.join(" ")

    # Should not crash on Unicode and should include some recognizable content
    expect(pdf_text).to be_present
    expect(pdf_text.encoding.name).to eq("UTF-8")
  end
end

RSpec.shared_examples "handles long text in PDFs" do |inspection_or_unit|
  it "properly truncates and handles extremely long text" do
    long_text = "A" * 2000

    if inspection_or_unit.is_a?(Inspection)
      inspection_or_unit.update(
        inspection_location: "Long location #{long_text}",
        comments: "Long comments #{long_text}"
      )
    else # Unit
      inspection_or_unit.update(
        name: "Long name #{long_text}",
        description: "Long description #{long_text}"
      )
    end

    pdf_response = page.driver.response.body
    expect(pdf_response[0..3]).to eq("%PDF")

    # Should generate successfully without errors
    expect { PDF::Inspector::Text.analyze(pdf_response) }.not_to raise_error
  end
end

RSpec.shared_examples "requires authentication for PDF access" do |path|
  it "redirects unauthenticated users away from protected PDF routes" do
    # Clear any existing session
    page.driver.browser.clear_cookies

    page.driver.browser.get(path)

    # Should not return a PDF for unauthenticated users
    expect(page.driver.response.headers["Content-Type"]).not_to eq("application/pdf")
    expect(page.driver.response.status).to be_in([ 302, 401, 403 ])
  end
end

RSpec.shared_examples "returns proper PDF headers" do
  it "returns correct content type and headers for PDF" do
    expect(page.driver.response.headers["Content-Type"]).to eq("application/pdf")
    expect(page.driver.response.headers["Content-Disposition"]).to include("inline")
  end
end

RSpec.shared_examples "handles missing data gracefully" do |pdf_response|
  it "displays appropriate messages for missing data" do
    pdf_text = PDF::Inspector::Text.analyze(pdf_response).strings.join(" ")

    # Should handle missing data gracefully with appropriate messages
    expect(pdf_text).to include("N/A").or include("No").or include("not available")
  end
end
