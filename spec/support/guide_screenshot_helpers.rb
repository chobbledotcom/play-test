module GuideScreenshotHelpers
  GUIDE_SCREENSHOTS_ROOT = Rails.public_path.join("guide_screenshots")

  def capture_guide_screenshot(caption, options = {})
    # return unless ENV["CAPTURE_GUIDE_SCREENSHOTS"] == "true"

    # Generate folder structure based on spec file path
    spec_path = RSpec.current_example.file_path
    spec_root = Rails.root.join("spec")

    # Get the relative path from spec directory
    relative_path = if spec_path.start_with?(spec_root.to_s)
      spec_path.sub(spec_root.to_s + "/", "")
    else
      spec_path
    end

    # Convert spec/features/inspections/create_spec.rb to features/inspections/create_spec
    folder_path = relative_path.gsub(/\.rb$/, "").gsub(/^\//, "")
    screenshot_dir = GUIDE_SCREENSHOTS_ROOT.join(folder_path)

    # Clear existing screenshots for this spec on first capture
    if !@guide_screenshots_initialized
      FileUtils.rm_rf(screenshot_dir) if screenshot_dir.exist?
      @guide_screenshots_initialized = true
    end

    # Ensure directory exists
    FileUtils.mkdir_p(screenshot_dir)

    # Load metadata for this specific test file
    metadata_file = screenshot_dir.join("metadata.json")
    metadata = load_metadata(metadata_file)

    # Generate filename based on sequence
    sequence = metadata["screenshots"].size + 1
    filename = "%03d_%s.png" % [sequence, caption.downcase.gsub(/[^a-z0-9]+/, "_")]
    filepath = screenshot_dir.join(filename)

    # Take the screenshot - requires js: true for the test
    unless page.driver.respond_to?(:save_screenshot)
      raise "Guide screenshots require js: true on the test scenario"
    end

    # Hide footer if this is the inspection screenshots spec
    if spec_path.include?("inspection_screenshots_spec")
      page.execute_script("
        var existingStyle = document.getElementById('guide-screenshot-style');
        if (!existingStyle) {
          var style = document.createElement('style');
          style.id = 'guide-screenshot-style';
          style.textContent = 'footer, #footer-rule { display: none !important; }';
          document.head.appendChild(style);
        }
      ")
    end

    # rubocop:disable Lint/Debugger
    page.save_screenshot(filepath.to_s, full: true) if Rails.env.test?
    # rubocop:enable Lint/Debugger

    # Add to metadata
    metadata["screenshots"] << {
      "sequence" => sequence,
      "filename" => filename,
      "caption" => caption,
      "example_description" => RSpec.current_example.description,
      "full_description" => RSpec.current_example.full_description,
      "timestamp" => Time.current.iso8601,
      "options" => options
    }

    # Save metadata for this test file
    save_metadata(metadata_file, metadata)

    # Log for debugging
    puts "📸 Guide screenshot saved: #{folder_path}/#{filename} - #{caption}"
  end

  private

  def load_metadata(metadata_file)
    return default_metadata unless metadata_file.exist?
    JSON.parse(metadata_file.read)
  rescue JSON::ParserError
    default_metadata
  end

  def save_metadata(metadata_file, metadata)
    metadata_file.write(JSON.pretty_generate(metadata))
  end

  def default_metadata
    {
      "spec_file" => RSpec.current_example.file_path,
      "created_at" => Time.current.iso8601,
      "updated_at" => Time.current.iso8601,
      "screenshots" => []
    }
  end
end

RSpec.configure do |config|
  config.include GuideScreenshotHelpers, type: :feature

  # Reset the initialized flag for each spec file
  config.before(:each, type: :feature) do
    @guide_screenshots_initialized = false
  end

  # Log when starting guide capture
  config.before(:suite) do
    if ENV["CAPTURE_GUIDE_SCREENSHOTS"] == "true"
      puts "📸 Guide screenshot capture is ENABLED"
      puts "   Screenshots will be saved to: public/guide_screenshots/"
      puts "   Old screenshots for each spec will be automatically cleared"
    end
  end
end
