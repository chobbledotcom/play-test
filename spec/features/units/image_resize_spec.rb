require "rails_helper"

RSpec.feature "Image resize functionality", type: :feature, js: true do
  let(:user) { create(:user) }
  let(:unit) { create(:unit, user: user) }

  before do
    sign_in(user)
  end

  scenario "resizes large images to JPEG before upload" do
    visit edit_unit_path(unit)

    # Create a test SVG file dynamically
    svg_content = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="3000" height="3000">
        <rect width="3000" height="3000" fill="red"/>
      </svg>
    SVG

    # Use JavaScript to create and attach the SVG file
    page.execute_script(<<~JS)
      // Create SVG blob
      const svgBlob = new Blob([`#{svg_content}`], { type: 'image/svg+xml' });
      const svgFile = new File([svgBlob], 'test.svg', { type: 'image/svg+xml' });

      // Get the file input
      const fileInput = document.querySelector('input[type="file"][accept*="image"]');

      // Create DataTransfer to simulate file selection
      const dataTransfer = new DataTransfer();
      dataTransfer.items.add(svgFile);
      fileInput.files = dataTransfer.files;

      // Trigger change event
      const event = new Event('change', { bubbles: true });
      fileInput.dispatchEvent(event);
    JS

    # Wait for image processing
    sleep 2

    # Check what type of file is actually in the input
    file_info = page.evaluate_script(<<-JS.strip)
      (function() {
        const fileInput = document.querySelector('input[type="file"][accept*="image"]');
        const file = fileInput.files[0];
        if (file) {
          return {
            name: file.name,
            type: file.type,
            size: file.size
          };
        }
        return null;
      })()
    JS

    expect(file_info).not_to be_nil
    expect(file_info["type"]).to eq("image/jpeg"), "Expected file to be converted to JPEG but got #{file_info["type"]}"
    expect(file_info["size"]).to be < 3000 * 3000, "Expected file to be resized/compressed"
  end

  scenario "handles JPEG uploads correctly" do
    visit edit_unit_path(unit)

    # Create a large JPEG-like file using canvas
    page.execute_script(<<~JS)
      // Create a canvas to generate a large image
      const canvas = document.createElement('canvas');
      canvas.width = 3000;
      canvas.height = 3000;
      const ctx = canvas.getContext('2d');

      // Fill with gradient to create some content
      const gradient = ctx.createLinearGradient(0, 0, 3000, 3000);
      gradient.addColorStop(0, 'red');
      gradient.addColorStop(1, 'blue');
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, 3000, 3000);

      // Convert to blob
      canvas.toBlob((blob) => {
        const file = new File([blob], 'large.jpg', { type: 'image/jpeg' });
      #{"  "}
        // Get the file input
        const fileInput = document.querySelector('input[type="file"][accept*="image"]');
      #{"  "}
        // Create DataTransfer to simulate file selection
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        fileInput.files = dataTransfer.files;
      #{"  "}
        // Store original size for comparison
        window.originalFileSize = file.size;
      #{"  "}
        // Trigger change event
        const event = new Event('change', { bubbles: true });
        fileInput.dispatchEvent(event);
      }, 'image/jpeg', 0.9);
    JS

    # Wait for image processing
    sleep 2

    # Check the processed file
    file_info = page.evaluate_script(<<-JS.strip)
      (function() {
        const fileInput = document.querySelector('input[type="file"][accept*="image"]');
        const file = fileInput.files[0];
        if (file) {
          return {
            name: file.name,
            type: file.type,
            size: file.size,
            originalSize: window.originalFileSize
          };
        }
        return null;
      })()
    JS

    expect(file_info).not_to be_nil
    expect(file_info["type"]).to eq("image/jpeg")
    expect(file_info["size"]).to be < file_info["originalSize"], "Expected file to be resized"
  end

  scenario "preserves small images unchanged" do
    visit edit_unit_path(unit)

    # Create a small image
    page.execute_script(<<~JS)
      // Create a small canvas
      const canvas = document.createElement('canvas');
      canvas.width = 100;
      canvas.height = 100;
      const ctx = canvas.getContext('2d');
      ctx.fillStyle = 'green';
      ctx.fillRect(0, 0, 100, 100);

      // Convert to blob
      canvas.toBlob((blob) => {
        const file = new File([blob], 'small.jpg', { type: 'image/jpeg' });
      #{"  "}
        // Get the file input
        const fileInput = document.querySelector('input[type="file"][accept*="image"]');
      #{"  "}
        // Create DataTransfer to simulate file selection
        const dataTransfer = new DataTransfer();
        dataTransfer.items.add(file);
        fileInput.files = dataTransfer.files;
      #{"  "}
        // Store original file info
        window.originalFile = {
          size: file.size,
          type: file.type
        };
      #{"  "}
        // Trigger change event
        const event = new Event('change', { bubbles: true });
        fileInput.dispatchEvent(event);
      }, 'image/jpeg', 0.9);
    JS

    # Wait a bit for any processing
    sleep 1

    # Check the file wasn't changed
    file_info = page.evaluate_script(<<-JS.strip)
      (function() {
        const fileInput = document.querySelector('input[type="file"][accept*="image"]');
        const file = fileInput.files[0];
        if (file) {
          return {
            name: file.name,
            type: file.type,
            size: file.size,
            originalSize: window.originalFile.size,
            originalType: window.originalFile.type
          };
        }
        return null;
      })()
    JS

    expect(file_info).not_to be_nil
    expect(file_info["type"]).to eq(file_info["originalType"])
    # Size should be the same for small images
    expect(file_info["size"]).to eq(file_info["originalSize"])
  end
end
