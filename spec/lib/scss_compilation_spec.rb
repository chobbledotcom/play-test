# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe "SCSS Compilation" do
  describe "nested SCSS compilation" do
    it "compiles nested SCSS to expanded CSS format" do
      # Create a temporary SCSS string with nested rules
      scss_content = <<~SCSS
        .container {
          width: 100%;
          padding: 20px;
        #{"  "}
          .header {
            background-color: #333;
            color: white;
        #{"    "}
            h1 {
              margin: 0;
              font-size: 24px;
            }
        #{"    "}
            nav {
              ul {
                list-style: none;
                padding: 0;
        #{"        "}
                li {
                  display: inline-block;
                  margin-right: 10px;
        #{"          "}
                  a {
                    color: #fff;
                    text-decoration: none;
        #{"            "}
                    &:hover {
                      text-decoration: underline;
                    }
                  }
                }
              }
            }
          }
        #{"  "}
          .content {
            padding: 20px;
        #{"    "}
            p {
              line-height: 1.6;
            }
          }
        }
      SCSS

      # Expected expanded CSS output (includes blank lines between rules)
      expected_css = <<~CSS
        .container {
          width: 100%;
          padding: 20px;
        }

        .container .header {
          background-color: #333;
          color: white;
        }

        .container .header h1 {
          margin: 0;
          font-size: 24px;
        }

        .container .header nav ul {
          list-style: none;
          padding: 0;
        }

        .container .header nav ul li {
          display: inline-block;
          margin-right: 10px;
        }

        .container .header nav ul li a {
          color: #fff;
          text-decoration: none;
        }

        .container .header nav ul li a:hover {
          text-decoration: underline;
        }

        .container .content {
          padding: 20px;
        }

        .container .content p {
          line-height: 1.6;
        }
      CSS

      # Use SassC to compile the SCSS
      require "sassc"
      engine = SassC::Engine.new(scss_content, style: :expanded)
      compiled_css = engine.render

      # With expanded style, output should match exactly
      expect(compiled_css.strip).to eq(expected_css.strip)
    end

    it "verifies that sass-rails is configured with expanded style" do
      # Check Rails configuration
      expect(Rails.application.config.sass.style).to eq(:expanded)
      expect(Rails.application.config.sass.preferred_syntax).to eq(:scss)
    end

    it "compiles SCSS variables correctly" do
      scss_with_variables = <<~SCSS
        $primary-color: #007bff;
        $padding-base: 15px;

        .button {
          background-color: $primary-color;
          padding: $padding-base;
        #{"  "}
          &.large {
            padding: $padding-base * 2;
          }
        }
      SCSS

      expected = <<~CSS
        .button {
          background-color: #007bff;
          padding: 15px;
        }

        .button.large {
          padding: 30px;
        }
      CSS

      require "sassc"
      engine = SassC::Engine.new(scss_with_variables, style: :expanded)
      compiled = engine.render

      # With expanded style, output should match exactly
      expect(compiled.strip).to eq(expected.strip)
    end

    it "compiles SCSS mixins correctly" do
      scss_with_mixins = <<~SCSS
        @mixin border-radius($radius) {
          border-radius: $radius;
        }

        .card {
          @include border-radius(8px);
          padding: 20px;
        }
      SCSS

      expected = <<~CSS
        .card {
          border-radius: 8px;
          padding: 20px;
        }
      CSS

      require "sassc"
      engine = SassC::Engine.new(scss_with_mixins, style: :expanded)
      compiled = engine.render

      # With expanded style, output should match exactly
      expect(compiled.strip).to eq(expected.strip)
    end
  end
end
