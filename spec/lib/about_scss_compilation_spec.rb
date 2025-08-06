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

      # Compile the SCSS using SassC
      begin
        require "sassc"
        engine = SassC::Engine.new(scss_content, style: :expanded)
        compiled_css = engine.render

        # Direct comparison with expanded style
        expect(compiled_css.strip).to eq(expected_css.strip)
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

      expected_css = <<~CSS
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

      begin
        require "sassc"
        engine = SassC::Engine.new(scss_content, style: :expanded)
        compiled = engine.render

        # Direct comparison with expanded style
        expect(compiled.strip).to eq(expected_css.strip)
      rescue LoadError
        skip "SassC gem not available, skipping compilation test"
      end
    end
  end
end

