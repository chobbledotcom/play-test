# Reusable code standards checker for both rake tasks and hooks
class CodeStandardsChecker
  HARDCODED_STRINGS_ALLOWED_PATHS = %w[/lib/ /seeds/ /spec/ /test/].freeze

  def initialize(max_method_lines: 20, max_file_lines: 500, max_line_length: 80)
    @max_method_lines = max_method_lines
    @max_file_lines = max_file_lines
    @max_line_length = max_line_length
  end

  def check_file(file_path)
    return [] unless File.exist?(file_path) && file_path.end_with?(".rb")

    relative_path = file_path.sub(Rails.root.join("").to_s, "")
    file_content = File.read(file_path)
    file_lines = file_content.lines

    violations = []
    violations.concat(check_file_length(relative_path, file_lines))
    violations.concat(check_line_lengths(relative_path, file_lines))
    violations.concat(check_method_lengths(relative_path, file_path))
    violations.concat(check_hardcoded_strings(relative_path, file_lines))

    violations
  end

  def check_multiple_files(file_paths)
    all_violations = []
    file_paths.each do |file_path|
      all_violations.concat(check_file(file_path))
    end
    all_violations
  end

  def format_violations(violations, show_summary: true)
    return "✅ All files meet code standards!" if violations.empty?

    output = []
    violations_by_type = violations.group_by { |v| v[:type] }

    output.concat(format_violations_by_type(violations_by_type))
    output.concat(format_summary(violations)) if show_summary

    output.join("\n")
  end

  private

  def format_violations_by_type(violations_by_type)
    output = []
    violations_by_type.each do |type, type_violations|
      type_name = type.to_s.upcase.tr("_", " ")
      output << "#{type_name} VIOLATIONS (#{type_violations.length}):"
      output << "-" * 50

      type_violations.each do |violation|
        line_ref = violation[:line_number] || ""
        output << "#{violation[:file]}:#{line_ref} #{violation[:message]}"
      end
      output << ""
    end
    output
  end

  def format_summary(violations)
    [
      "=" * 80,
      "TOTAL: #{violations.length} violations found"
    ]
  end

  def check_file_length(relative_path, file_lines)
    return [] unless file_lines.length > @max_file_lines

    [ {
      file: relative_path,
      type: :file_length,
      message: "#{file_lines.length} lines (max #{@max_file_lines})"
    } ]
  end

  def check_line_lengths(relative_path, file_lines)
    violations = []
    file_lines.each_with_index do |line, index|
      next unless line.chomp.length > @max_line_length

      violations << {
        file: relative_path,
        type: :line_length,
        line_number: index + 1,
        length: line.chomp.length,
        message: build_line_length_message(index + 1, line.chomp.length)
      }
    end
    violations
  end

  def check_method_lengths(relative_path, file_path)
    methods = extract_methods_from_file(file_path)
    long_methods = methods.select { |m| m[:length] > @max_method_lines }

    long_methods.map do |method|
      {
        file: relative_path,
        type: :method_length,
        line_number: method[:start_line],
        message: build_method_length_message(method)
      }
    end
  end

  def check_hardcoded_strings(relative_path, file_lines)
    return [] if skip_hardcoded_strings?(relative_path)

    violations = []
    file_lines.each_with_index do |line, index|
      line_violations = check_line_for_hardcoded_strings(
        relative_path, line, index + 1
      )
      violations.concat(line_violations)
    end
    violations
  end

  def check_line_for_hardcoded_strings(relative_path, line, line_number)
    stripped = line.strip
    return [] if should_skip_line?(stripped)

    hardcoded_strings = extract_quoted_strings(stripped)

    hardcoded_strings.filter_map do |string|
      next unless should_flag_string?(string)

      {
        file: relative_path,
        type: :hardcoded_string,
        line_number: line_number,
        message: build_hardcoded_string_message(line_number, string)
      }
    end
  end

  def skip_hardcoded_strings?(relative_path)
    allowed_path = HARDCODED_STRINGS_ALLOWED_PATHS.any? do |path|
      relative_path.include?(path)
    end
    allowed_path || relative_path.include?("seed_data_service.rb")
  end

  def should_skip_line?(stripped)
    stripped.start_with?("#") ||
      stripped.match?(/\/.*\//) ||
      stripped.include?("I18n.t") ||
      stripped.include?("Rails.logger") ||
      stripped.include?("puts") ||
      stripped.include?("print")
  end

  def extract_quoted_strings(stripped)
    strings = stripped.scan(/"([^"]*)"/).flatten
    strings += stripped.scan(/'([^']*)'/).flatten
    strings
  end

  def should_flag_string?(string)
    return false unless string.match?(/\w/)
    return false if technical_string?(string)
    return false if string.length < 3
    return false if string.match?(/^#\{.*\}$/)

    string.match?(/[A-Z].*[a-z]/) || string.include?(" ")
  end

  def technical_string?(string)
    string.match?(/^[a-z_]+$/) ||
      string.match?(/^[A-Z_]+$/) ||
      string.match?(/^[a-z]+\.[a-z]+/) ||
      string.match?(/^\//) ||
      string.match?(/^[a-z]+_[a-z]+_path$/) ||
      string.match?(/^\w+:/)
  end

  def build_line_length_message(line_number, length)
    "Line #{line_number}: #{length} chars (max #{@max_line_length})"
  end

  def build_method_length_message(method)
    name = method[:name]
    length = method[:length]
    "Method '#{name}' is #{length} lines (max #{@max_method_lines})"
  end

  def build_hardcoded_string_message(line_number, string)
    "Line #{line_number}: Hardcoded string '#{string}' - use I18n.t() instead"
  end

  def extract_methods_from_file(file_path)
    content = File.read(file_path)
    methods = []
    parser_state = { current_method: nil, indent_level: 0, method_start_line: 0 }

    content.lines.each_with_index do |line, index|
      process_line_for_methods(
        line,
        index + 1,
        methods,
        parser_state,
        file_path
      )
    end

    finalize_last_method(methods, parser_state, content, file_path)
    methods
  end

  def process_line_for_methods(line, line_number, methods, state, file_path)
    stripped = line.strip

    if method_definition?(stripped)
      save_current_method(methods, state, line_number, file_path)
      start_new_method(stripped, line, line_number, state)
    elsif method_end?(
      state[:current_method],
      stripped,
      line,
      state[:indent_level]
    )
      finish_current_method(methods, state, line_number, file_path)
    end
  end

  def save_current_method(methods, state, line_number, file_path)
    return unless state[:current_method]

    add_method_to_list(methods, state, line_number, file_path)
  end

  def start_new_method(stripped, line, line_number, state)
    state[:current_method] = extract_method_name(stripped)
    state[:method_start_line] = line_number
    state[:indent_level] = line.match(/^(\s*)/)[1].length
  end

  def finish_current_method(methods, state, line_number, file_path)
    add_method_to_list(methods, state, line_number, file_path)
    state[:current_method] = nil
  end

  def finalize_last_method(methods, state, content, file_path)
    return unless state[:current_method]

    end_line = content.lines.length
    add_method_to_list(methods, state, end_line, file_path)
  end

  def add_method_to_list(methods, state, end_line, file_path)
    methods << build_method_info(
      state[:current_method], state[:method_start_line], end_line, file_path
    )
  end

  def method_definition?(stripped)
    /^(private|protected|public\s+)?def\s+/.match?(stripped)
  end

  def method_end?(current_method, stripped, line, indent_level)
    return false unless current_method && !stripped.empty?

    current_indent = line.match(/^(\s*)/)[1].length
    stripped == "end" && current_indent <= indent_level
  end

  def extract_method_name(stripped)
    stripped.match(/def\s+([^\s\(]+)/)[1]
  end

  def build_method_info(method_name, start_line, end_line, file_path)
    {
      name: method_name,
      start_line: start_line,
      end_line: end_line,
      length: end_line - start_line + 1,
      file: file_path
    }
  end

  def build_final_method_info(method_name, start_line, content, file_path)
    end_line = content.lines.length
    {
      name: method_name,
      start_line: start_line,
      end_line: end_line,
      length: end_line - start_line + 1,
      file: file_path
    }
  end
end
