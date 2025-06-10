#!/usr/bin/env ruby

def usage
  puts "Usage: ruby coverage_check.rb <file_path>"
  puts "Example: ruby coverage_check.rb app/models/user.rb"
  exit 1
end

def get_coverage_from_html(target_path)
  html_file = "coverage/index.html"

  unless File.exist?(html_file)
    puts "Error: Coverage HTML file not found at #{html_file}"
    puts "Run tests first to generate coverage report"
    exit 1
  end

  html_content = File.read(html_file)

  # Look for the file in the HTML table
  # The pattern is: <a href="#hash" class="src_link" title="path">path</a>
  file_pattern = Regexp.escape(target_path)

  # Find the table row containing our file
  # Structure: title="path">path</a></td><td>86.21 %</td><td>175</td><td>87</td><td>75</td><td>12</td><td>8.67</td><td>76.67 %</td><td>30</td><td>23</td><td>7</td>
  if html_content =~ /title="#{file_pattern}"[^>]*>#{file_pattern}<\/a><\/td>\s*<td[^>]*>([0-9.]+)\s*%<\/td>\s*<td[^>]*>(\d+)<\/td>\s*<td[^>]*>(\d+)<\/td>\s*<td[^>]*>(\d+)<\/td>\s*<td[^>]*>(\d+)<\/td>\s*<td[^>]*>[0-9.]+<\/td>\s*<td[^>]*>([0-9.]+)\s*%<\/td>\s*<td[^>]*>(\d+)<\/td>\s*<td[^>]*>(\d+)<\/td>\s*<td[^>]*>(\d+)<\/td>/m
    line_coverage = $1.to_f
    $2.to_i
    relevant_lines = $3.to_i
    covered_lines = $4.to_i
    missed_lines = $5.to_i
    branch_coverage = $6.to_f
    total_branches = $7.to_i
    covered_branches = $8.to_i
    missed_branches = $9.to_i

    puts "#{target_path}: #{line_coverage}% lines covered"
    puts "#{relevant_lines} relevant lines. #{covered_lines} lines covered and #{missed_lines} lines missed."
    puts "#{branch_coverage}% branches covered"
    puts "#{total_branches} total branches, #{covered_branches} branches covered and #{missed_branches} branches missed."

  else
    puts "File not found in coverage report: #{target_path}"
    puts "Available files in coverage report:"

    # Extract all file paths from the HTML
    html_content.scan(/title="([^"]+\.rb)"/) do |match|
      puts "  #{match[0]}"
    end
  end
end

# Main execution
if ARGV.empty?
  usage
end

target_file = ARGV[0]
get_coverage_from_html(target_file)
