namespace :code_standards do
  desc "Check code standards violations (read-only)"
  task check: :environment do
    # Standards from CLAUDE.md
    max_method_lines = 20
    max_file_lines = 500
    max_line_length = 80

    # Directories to check
    directories_to_check = %w[
      app/controllers
      app/models
      app/services
      app/helpers
      app/jobs
      lib
    ]
    def ruby_files_in(directory)
      Dir.glob(Rails.root.join("#{directory}/**/*.rb").to_s)
    end

    def extract_methods_from_file(file_path)
      content = File.read(file_path)
      methods = []
      current_method = nil
      indent_level = 0
      method_start_line = 0

      content.lines.each_with_index do |line, index|
        line_number = index + 1
        stripped = line.strip

        # Detect method definition
        if /^(private|protected|public\s+)?def\s+/.match?(stripped)
          # Save previous method if exists
          if current_method
            methods << {
              name: current_method,
              start_line: method_start_line,
              end_line: line_number - 1,
              length: line_number - method_start_line,
              file: file_path
            }
          end

          # Start new method
          method_name = stripped.match(/def\s+([^\s\(]+)/)[1]
          current_method = method_name
          method_start_line = line_number
          indent_level = line.match(/^(\s*)/)[1].length
        elsif current_method && !stripped.empty?
          # Check if we've reached the end of the current method
          current_indent = line.match(/^(\s*)/)[1].length

          # Method ends when we hit 'end' at the same or lesser indentation
          if stripped == "end" && current_indent <= indent_level
            methods << {
              name: current_method,
              start_line: method_start_line,
              end_line: line_number,
              length: line_number - method_start_line + 1,
              file: file_path
            }
            current_method = nil
          end
        end
      end

      # Handle case where file ends without explicit 'end'
      if current_method
        methods << {
          name: current_method,
          start_line: method_start_line,
          end_line: content.lines.length,
          length: content.lines.length - method_start_line + 1,
          file: file_path
        }
      end

      methods
    end

    # Collect all violations
    all_violations = []

    directories_to_check.each do |directory|
      ruby_files_in(directory).each do |file_path|
        relative_path = file_path.sub(Rails.root.join("").to_s, "")
        file_content = File.read(file_path)
        file_lines = file_content.lines
        methods = extract_methods_from_file(file_path)

        # Check file length
        if file_lines.length > max_file_lines
          all_violations << {
            file: relative_path,
            type: :file_length,
            message: "#{file_lines.length} lines (max #{max_file_lines})"
          }
        end

        # Check line length
        file_lines.each_with_index do |line, index|
          if line.chomp.length > max_line_length
            all_violations << {
              file: relative_path,
              type: :line_length,
              line_number: index + 1,
              length: line.chomp.length,
              message: "Line #{index + 1}: #{line.chomp.length} chars (max #{max_line_length})"
            }
          end
        end

        # Check method length
        long_methods = methods.select { |m| m[:length] > max_method_lines }
        long_methods.each do |method|
          all_violations << {
            file: relative_path,
            type: :method_length,
            line_number: method[:start_line],
            message: "Method '#{method[:name]}' is #{method[:length]} lines (max #{max_method_lines})"
          }
        end

        # Check for hardcoded strings (excluding test files)
        unless relative_path.include?("/spec/") || relative_path.include?("/test/")
          file_lines.each_with_index do |line, index|
            # Skip comments and regex patterns
            stripped = line.strip
            next if stripped.start_with?("#")
            next if stripped.match?(/\/.*\//) # Skip regex literals
            next if stripped.include?("I18n.t") # Skip I18n calls
            next if stripped.include?("Rails.logger") # Skip logger messages
            next if stripped.include?("puts") || stripped.include?("print") # Skip debug output

            # Look for hardcoded user-facing strings (quoted strings not in specific contexts)
            hardcoded_strings = stripped.scan(/"([^"]*[a-zA-Z][^"]*)"/).flatten
            hardcoded_strings += stripped.scan(/'([^']*[a-zA-Z][^']*)'/).flatten

            hardcoded_strings.each do |string|
              # Skip technical strings (method names, file paths, etc.)
              next if string.match?(/^[a-z_]+$/) # snake_case identifiers
              next if string.match?(/^[A-Z_]+$/) # CONSTANTS
              next if string.match?(/^[a-z]+\.[a-z]+/) # file extensions
              next if string.match?(/^\//) # paths
              next if string.match?(/^[a-z]+_[a-z]+_path$/) # Rails path helpers
              next if string.match?(/^\w+:/) # Hash keys or XML namespaces
              next if string.length < 3 # Very short strings

              # If it looks like user-facing text, flag it
              if string.match?(/[A-Z].*[a-z]/) || string.include?(" ")
                all_violations << {
                  file: relative_path,
                  type: :hardcoded_string,
                  line_number: index + 1,
                  message: "Line #{index + 1}: Hardcoded string '#{string}' - use I18n.t() instead"
                }
              end
            end
          end
        end
      end
    end

    # Report results
    puts "\n" + "=" * 80
    puts "CODE STANDARDS REPORT"
    puts "=" * 80

    if all_violations.empty?
      puts "✅ All files meet code standards!"
      exit 0
    end

    violations_by_type = all_violations.group_by { |v| v[:type] }

    violations_by_type.each do |type, violations|
      puts "\n#{type.to_s.upcase.tr("_", " ")} VIOLATIONS (#{violations.length}):"
      puts "-" * 50

      violations.each do |violation|
        puts "#{violation[:file]}:#{violation[:line_number] || ""} #{violation[:message]}"
      end
    end

    puts "\n" + "=" * 80
    puts "TOTAL: #{all_violations.length} violations found"

    puts "\nTo apply StandardRB formatting: bundle exec standardrb --fix"
    puts "To lint only modified files: rake code_standards:lint_modified"

    puts "\nFORMATTING PREFERENCES (StandardRB compatible - see CLAUDE.md):"
    puts "• Arrays: alphabetical order when order doesn't matter, use %i[] %w[]"
    puts "• Arrays: one per line when over 80 chars, maintain alphabetical order"
    puts "• Method calls: extract variables or break at method chain points"
    puts "• Hash parameters: extract to variables for readability"
    puts "• Long strings: extract to variables or break with backslash"
    puts "• Comments: break at sentence boundaries (StandardRB preserves these)"
    puts "• Avoid parameter alignment - StandardRB collapses whitespace"

    exit 1 if all_violations.any?
  end

  desc "Run StandardRB linter on modified files only"
  task :lint_modified do
    modified_files = `git diff --name-only HEAD`.split("\n").select { |f| f.end_with?(".rb") }

    if modified_files.empty?
      puts "No modified Ruby files to lint."
    else
      puts "Linting #{modified_files.length} modified Ruby files..."
      system("bundle exec standardrb --fix #{modified_files.join(" ")}")
    end
  end

  desc "Full workflow: lint with StandardRB then check standards"
  task :fix_all do
    puts "Step 1: Running StandardRB on all Ruby files..."
    system("bundle exec standardrb --fix app/ lib/ spec/")

    puts "\nStep 2: Checking remaining code standards violations..."
    Rake::Task["code_standards:check"].invoke
  rescue SystemExit
    puts "\nWorkflow complete. Check output above for any remaining violations."
  end
end

desc "Check code standards (alias for code_standards:check)"
task code_standards: "code_standards:check"
