# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "About SCSS Compilation" do
  describe "about.scss compilation" do
    it "compiles about.scss to match the expected CSS structure" do
      # Read the SCSS file
      scss_path = Rails.root.join("app/assets/stylesheets/about.scss")
      scss_content = File.read(scss_path)

      # Expected CSS output (using class selector)
      expected_css = <<~CSS
        /* About page specific styles */
        .about article {
          max-width: 60rem;
          margin: 0 auto;
          text-align: left;
        }

        .about p {
          text-align: left;
          line-height: 1.6;
        }

        .about table {
          text-align: left;
        }

        .about th,
        .about td {
          text-align: left;
        }
      CSS

      # Try to compile the SCSS using SassC if available
      begin
        require "sassc"
        engine = SassC::Engine.new(scss_content, style: :expanded)
        compiled_css = engine.render

        # Normalize whitespace for comparison
        # Remove extra spaces, normalize line endings
        normalize = ->(str) {
          str.strip
            .gsub(/\/\*.*?\*\//m, "") # Remove comments for comparison
            .gsub(/\s+/, " ")
            .gsub(/\s*{\s*/, " { ")
            .gsub(/\s*}\s*/, " } ")
            .gsub(/\s*;\s*/, "; ")
            .gsub(/}\s*/, "}\n")
            .strip
        }

        normalized_compiled = normalize.call(compiled_css)
        normalize.call(expected_css)

        # Check that all the selectors are present
        expect(normalized_compiled).to include(".about article")
        expect(normalized_compiled).to include(".about p")
        expect(normalized_compiled).to include(".about table")
        expect(normalized_compiled).to include(".about th")
        expect(normalized_compiled).to include(".about td")

        # Check that the properties are present
        expect(normalized_compiled).to include("max-width: 60rem")
        expect(normalized_compiled).to include("margin: 0 auto")
        expect(normalized_compiled).to include("text-align: left")
        expect(normalized_compiled).to include("line-height: 1.6")
      rescue LoadError
        skip "SassC gem not available, skipping compilation test"
      end
    end

    it "produces functionally equivalent CSS from nested SCSS" do
      scss_content = <<~SCSS
        .about {
          article {
            max-width: 60rem;
            margin: 0 auto;
            text-align: left;
          }

          p {
            text-align: left;
            line-height: 1.6;
          }

          table {
            text-align: left;
          }

          th,
          td {
            text-align: left;
          }
        }
      SCSS

      begin
        require "sassc"
        engine = SassC::Engine.new(scss_content, style: :expanded)
        compiled = engine.render

        # Verify the compiled output contains all expected rules
        expect(compiled).to match(/\.about article\s*{[^}]*max-width:\s*60rem/)
        expect(compiled).to match(/\.about article\s*{[^}]*margin:\s*0 auto/)
        expect(compiled).to match(/\.about p\s*{[^}]*line-height:\s*1\.6/)
        expect(compiled).to match(/\.about table\s*{[^}]*text-align:\s*left/)
        about_th_td = /\.about th,\s*\.about td\s*{[^}]*text-align:\s*left/
        expect(compiled).to match(about_th_td)
      rescue LoadError
        skip "SassC gem not available, skipping compilation test"
      end
    end
  end
end
