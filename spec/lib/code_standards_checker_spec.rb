require "rails_helper"

RSpec.describe CodeStandardsChecker do
  let(:checker) { described_class.new }
  let(:temp_file) { Tempfile.new(["test", ".rb"]) }

  after do
    temp_file.close
    temp_file.unlink
  end

  describe "#initialize" do
    it "uses default values when no parameters are provided" do
      expect(checker.instance_variable_get(:@max_method_lines)).to eq(20)
      expect(checker.instance_variable_get(:@max_file_lines)).to eq(500)
      expect(checker.instance_variable_get(:@max_line_length)).to eq(80)
    end

    it "accepts custom values" do
      custom_checker = described_class.new(
        max_method_lines: 30,
        max_file_lines: 600,
        max_line_length: 100
      )
      expect(custom_checker.instance_variable_get(:@max_method_lines)).to eq(30)
      expect(custom_checker.instance_variable_get(:@max_file_lines)).to eq(600)
      expect(custom_checker.instance_variable_get(:@max_line_length)).to eq(100)
    end
  end

  describe "#check_file" do
    context "when file doesn't exist" do
      it "returns empty array" do
        expect(checker.check_file("nonexistent.rb")).to eq([])
      end
    end

    context "when file is not a Ruby file" do
      it "returns empty array" do
        non_ruby_file = Tempfile.new(["test", ".txt"])
        expect(checker.check_file(non_ruby_file.path)).to eq([])
        non_ruby_file.close
        non_ruby_file.unlink
      end
    end

    context "when file has violations" do
      it "detects all types of violations" do
        content = <<~RUBY
          class TestClass
            def long_method
              puts "This method"
              puts "has many"
              puts "lines that"
              puts "exceed the"
              puts "maximum allowed"
              puts "method length"
              puts "of 20 lines"
              puts "so it should"
              puts "be flagged"
              puts "as a violation"
              puts "in our tests"
              puts "and we need"
              puts "more lines"
              puts "to exceed"
              puts "the limit"
              puts "almost there"
              puts "just a few"
              puts "more lines"
              puts "and done"
            end

            def method_with_long_line
              very_long_line = "This is a very long line that exceeds the maximum allowed line length of 80 characters"
            end

            def method_with_hardcoded_string
              message = "This is a hardcoded string"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)

        expect(violations).to include(
          a_hash_including(type: :method_length),
          a_hash_including(type: :line_length),
          a_hash_including(type: :hardcoded_string)
        )
      end
    end
  end

  describe "#check_multiple_files" do
    it "checks all provided files" do
      file1 = Tempfile.new(["test1", ".rb"])
      file2 = Tempfile.new(["test2", ".rb"])

      # Use very long lines to ensure line length violations
      file1.write("def method1; very_long_variable_name = 'This is a very long line that will definitely exceed the 80 character limit'; end")
      file2.write("def method2; another_very_long_variable = 'Another very long line that will also exceed the 80 character limit'; end")

      file1.rewind
      file2.rewind

      violations = checker.check_multiple_files([file1.path, file2.path])

      expect(violations.length).to be >= 2
      # Should include at least line length violations
      line_violations = violations.select { |v| v[:type] == :line_length }
      expect(line_violations.length).to be >= 2

      file1.close
      file1.unlink
      file2.close
      file2.unlink
    end
  end

  describe "file length checking" do
    it "flags files exceeding maximum lines" do
      content = Array.new(501, "# comment line").join("\n")
      temp_file.write(content)
      temp_file.rewind

      violations = checker.check_file(temp_file.path)
      file_length_violations = violations.select { |v| v[:type] == :file_length }

      expect(file_length_violations.length).to eq(1)
      expect(file_length_violations.first[:message]).to include("501 lines")
    end

    it "doesn't flag files within limits" do
      content = Array.new(499, "# comment line").join("\n")
      temp_file.write(content)
      temp_file.rewind

      violations = checker.check_file(temp_file.path)
      file_length_violations = violations.select { |v| v[:type] == :file_length }

      expect(file_length_violations).to be_empty
    end
  end

  describe "line length checking" do
    it "flags lines exceeding maximum length" do
      content = <<~RUBY
        class Test
          def method
            short_line = "ok"
            very_long_line = "This line is definitely going to exceed the maximum allowed line length of 80 characters"
          end
        end
      RUBY

      temp_file.write(content)
      temp_file.rewind

      violations = checker.check_file(temp_file.path)
      line_length_violations = violations.select { |v| v[:type] == :line_length }

      expect(line_length_violations.length).to eq(1)
      expect(line_length_violations.first[:line_number]).to eq(4)
      expect(line_length_violations.first[:message]).to include("Line 4:")
    end

    it "calculates line length correctly ignoring trailing newline" do
      exactly_80_chars = "a" * 80
      content = "#{exactly_80_chars}\n"

      temp_file.write(content)
      temp_file.rewind

      violations = checker.check_file(temp_file.path)
      line_length_violations = violations.select { |v| v[:type] == :line_length }

      expect(line_length_violations).to be_empty
    end
  end

  describe "method length checking" do
    context "with regular method definitions" do
      it "flags methods exceeding maximum lines" do
        content = <<~RUBY
          class Test
            def short_method
              puts "ok"
            end

            def long_method
              puts "line 1"
              puts "line 2"
              puts "line 3"
              puts "line 4"
              puts "line 5"
              puts "line 6"
              puts "line 7"
              puts "line 8"
              puts "line 9"
              puts "line 10"
              puts "line 11"
              puts "line 12"
              puts "line 13"
              puts "line 14"
              puts "line 15"
              puts "line 16"
              puts "line 17"
              puts "line 18"
              puts "line 19"
              puts "line 20"
              puts "line 21"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        method_violations = violations.select { |v| v[:type] == :method_length }

        expect(method_violations.length).to eq(1)
        expect(method_violations.first[:message]).to include("long_method")
        expect(method_violations.first[:message]).to include("23 lines")
      end
    end

    context "with endless methods" do
      it "counts endless methods as single line" do
        content = <<~RUBY
          class Test
            def endless_method = puts "single line"
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        method_violations = violations.select { |v| v[:type] == :method_length }

        expect(method_violations).to be_empty
      end
    end

    context "with visibility modifiers" do
      it "correctly identifies methods with private/protected/public" do
        content = <<~RUBY
          class Test
            def private_method
              puts "line 1"
              puts "line 2"
              puts "line 3"
              puts "line 4"
              puts "line 5"
              puts "line 6"
              puts "line 7"
              puts "line 8"
              puts "line 9"
              puts "line 10"
              puts "line 11"
              puts "line 12"
              puts "line 13"
              puts "line 14"
              puts "line 15"
              puts "line 16"
              puts "line 17"
              puts "line 18"
              puts "line 19"
              puts "line 20"
              puts "line 21"
            end
            private :private_method

            protected def protected_method
              puts "ok"
            end

            public def public_method
              puts "ok"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        expect(violations).to include(
          a_hash_including(
            type: :method_length,
            message: a_string_including("private_method")
          )
        )
      end
    end
  end

  describe "hardcoded string checking" do
    context "in allowed paths" do
      it "skips checking in /lib/ directory" do
        allow(temp_file).to receive(:path).and_return("/lib/test.rb")
        content = 'puts "This hardcoded string should be ignored"'

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "skips checking in /spec/ directory" do
        allow(temp_file).to receive(:path).and_return("/spec/test_spec.rb")
        content = 'expect(page).to have_content("Test Content")'

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "skips seed_data_service.rb files" do
        allow(temp_file).to receive(:path).and_return("/app/services/seed_data_service.rb")
        content = 'create(name: "Seed Data")'

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end
    end

    context "string detection rules" do
      it "flags user-facing strings" do
        content = <<~RUBY
          class Test
            def method
              message = "User friendly message"
              error = "Something went wrong"
              title = "Page Title"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations.length).to eq(3)
      end

      it "ignores technical strings" do
        content = <<~RUBY
          class Test
            def method
              key = "user_id"
              constant = "CONSTANT_NAME"
              path = "users_path"
              method_name = "find_by_email"
              namespace = "admin.users"
              regex_pattern = "/pattern/"
              symbol_key = "symbol:"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "ignores strings in comments" do
        content = <<~RUBY
          class Test
            # This is a comment with "hardcoded string"
            def method
              puts "test" # Another comment with "string"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "ignores strings with I18n.t" do
        content = <<~RUBY
          class Test
            def method
              message = I18n.t("users.welcome")
              error = I18n.t('errors.invalid')
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "ignores strings in logger statements" do
        content = <<~RUBY
          class Test
            def method
              Rails.logger.info "Processing user"
              puts "Debug output"
              print "Another debug"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "ignores short strings" do
        content = <<~RUBY
          class Test
            def method
              a = "ab"
              b = "xy"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end

      it "ignores interpolation placeholders" do
        content = <<~RUBY
          class Test
            def method
              template = "\#{user}"
              another = '\#{count}'
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations).to be_empty
      end
    end
  end

  describe "#format_violations" do
    let(:violations) do
      [
        {
          file: "app/models/user.rb",
          type: :file_length,
          message: "501 lines (max 500)"
        },
        {
          file: "app/models/user.rb",
          type: :line_length,
          line_number: 42,
          message: "Line 42: 85 chars (max 80)"
        },
        {
          file: "app/models/user.rb",
          type: :method_length,
          line_number: 10,
          message: "Method 'calculate' is 25 lines (max 20)"
        },
        {
          file: "app/controllers/users_controller.rb",
          type: :hardcoded_string,
          line_number: 15,
          message: "Line 15: Hardcoded string 'Welcome' - use I18n.t() instead"
        }
      ]
    end

    context "with violations" do
      it "groups violations by type" do
        output = checker.format_violations(violations)

        expect(output).to include("FILE LENGTH VIOLATIONS (1):")
        expect(output).to include("LINE LENGTH VIOLATIONS (1):")
        expect(output).to include("METHOD LENGTH VIOLATIONS (1):")
        expect(output).to include("HARDCODED STRING VIOLATIONS (1):")
      end

      it "formats each violation correctly" do
        output = checker.format_violations(violations)

        expect(output).to include("app/models/user.rb: 501 lines (max 500)")
        expect(output).to include("app/models/user.rb:42 Line 42: 85 chars (max 80)")
        expect(output).to include("app/models/user.rb:10 Method 'calculate' is 25 lines (max 20)")
        expect(output).to include("app/controllers/users_controller.rb:15 Line 15: Hardcoded string 'Welcome' - use I18n.t() instead")
      end

      it "includes summary by default" do
        output = checker.format_violations(violations)

        expect(output).to include("TOTAL: 4 violations found")
        expect(output).to include("=" * 80)
      end

      it "can skip summary" do
        output = checker.format_violations(violations, show_summary: false)

        expect(output).not_to include("TOTAL: 4 violations found")
      end
    end

    context "without violations" do
      it "returns success message" do
        output = checker.format_violations([])

        expect(output).to eq("✅ All files meet code standards!")
      end
    end
  end

  describe "edge cases" do
    context "with nested methods" do
      it "correctly identifies nested method boundaries" do
        content = <<~RUBY
          class Test
            def outer_method
              inner = lambda do
                puts "inside lambda"
              end

              define_method :dynamic_method do
                puts "dynamic"
              end
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        method_violations = violations.select { |v| v[:type] == :method_length }

        # Should only count outer_method, not the inner blocks
        expect(method_violations).to be_empty
      end
    end

    context "with method at end of file without final newline" do
      it "correctly calculates method length" do
        content = "class Test\n  def method\n    " + Array.new(21, 'puts "line"').join("\n    ") + "\n  end\nend"

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        method_violations = violations.select { |v| v[:type] == :method_length }

        expect(method_violations.length).to eq(1)
      end
    end

    context "with single and double quotes" do
      it "detects hardcoded strings in both quote styles" do
        content = <<~RUBY
          class Test
            def method
              single = 'Single quoted string'
              double = "Double quoted string"
            end
          end
        RUBY

        temp_file.write(content)
        temp_file.rewind

        violations = checker.check_file(temp_file.path)
        hardcoded_violations = violations.select { |v| v[:type] == :hardcoded_string }

        expect(hardcoded_violations.length).to eq(2)
      end
    end
  end
end