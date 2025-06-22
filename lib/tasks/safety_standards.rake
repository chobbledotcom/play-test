namespace :safety_standards do
  desc "Download EN 14960-1 (2019) PDF and convert to text for verification"
  task download_and_convert: :environment do
    require "net/http"
    require "uri"

    pdf_url = "https://nobelcert.com/DataFiles/FreeUpload/EN%2014960-1%20(2019).pdf"
    pdf_path = Rails.root.join("tmp/EN_14960-1_2019.pdf")
    txt_path = Rails.root.join("tmp/EN_14960-1_2019.txt")

    puts "📥 Downloading EN 14960-1 (2019) PDF..."

    begin
      # Download PDF
      uri = URI(pdf_url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)

        if response.code == "200"
          File.binwrite(pdf_path, response.body)
          puts "✅ PDF downloaded successfully to #{pdf_path}"
          puts "📄 File size: #{File.size(pdf_path)} bytes"
        else
          puts "❌ Failed to download PDF: HTTP #{response.code}"
          exit 1
        end
      end

      # Convert PDF to text using pdf-inspector gem
      puts "🔄 Converting PDF to text using pdf-inspector gem..."

      begin
        require "pdf/inspector"

        # Read the PDF file content
        pdf_content = File.read(pdf_path, mode: "rb")

        # Analyze the text in the PDF
        text_analysis = PDF::Inspector::Text.analyze(pdf_content)

        # Get the text strings and filter out watermarks
        text_strings = text_analysis.strings

        # Filter out watermark lines (like "Provided by : www.spic.ir")
        filtered_strings = text_strings.reject do |string|
          string.include?("www.spic.ir") ||
            string.include?("Provided by") ||
            string.strip.length < 3  # Remove very short strings
        end

        text_content = filtered_strings.join(" ")

        # Clean up the text and format it properly
        formatted_text = text_content.gsub(/\s+/, " ").strip

        puts "🔍 Debug info:"
        puts "   Total text fragments found: #{text_strings.length}"
        puts "   Fragments after filtering: #{filtered_strings.length}"
        puts "   Sample original fragments: #{text_strings.first(10).inspect}"
        puts "   Sample filtered fragments: #{filtered_strings.first(10).inspect}"

        if formatted_text.empty?
          puts "❌ No usable text after filtering watermarks"
          puts "💡 Let's try with less aggressive filtering..."

          # Try less aggressive filtering - only remove exact watermark matches
          less_filtered = text_strings.reject { |s| s.strip == "Provided by : www.spic.ir" }
          alternative_text = less_filtered.join(" ").gsub(/\s+/, " ").strip

          if alternative_text.length > 100  # If we have substantial text
            formatted_text = alternative_text
            puts "✅ Using less aggressive filtering, found #{alternative_text.length} characters"
          else
            puts "❌ Still no substantial text found"
            puts "📋 All fragments: #{text_strings.inspect}"
            exit 1
          end
        end

        # Split into lines for better readability (preserve some structure)
        # Try to preserve sentence structure by splitting on periods followed by spaces
        lines = formatted_text.split(/\.\s+/).map(&:strip).reject(&:empty?)
        lines = lines.map { |line| line.end_with?(".") ? line : line + "." }

        # Write to text file
        File.open(txt_path, "w") do |file|
          lines.each { |line| file.puts(line) }
        end

        puts "✅ PDF converted to text successfully"
        puts "📝 Text file: #{txt_path}"

        # Show some stats
        line_count = lines.count
        word_count = formatted_text.split.count
        char_count = formatted_text.length

        puts "📊 Text file statistics:"
        puts "   Lines: #{line_count}"
        puts "   Words: #{word_count}"
        puts "   Characters: #{char_count}"
        puts "   Text fragments found: #{text_strings.length}"

        puts "\n🔍 First 10 lines of converted text:"
        puts "-" * 50
        lines.first(10).each_with_index do |line, index|
          puts "#{(index + 1).to_s.rjust(3)}: #{line}"
        end
        puts "-" * 50
      rescue => e
        puts "❌ Failed to convert PDF to text: #{e.message}"
        puts "📋 Error details: #{e.class} - #{e.backtrace.first}"
        exit 1
      end
    rescue => e
      puts "❌ Error: #{e.message}"
      exit 1
    end
  end

  desc "Search for safety standard references in EN 14960-1 text"
  task verify_standards: :environment do
    txt_path = Rails.root.join("14960.md")

    unless File.exist?(txt_path)
      puts "❌ Text file (14960.md) not found."
      exit 1
    end

    puts "🔍 Searching for safety standard references in EN 14960-1..."
    puts "=" * 80

    # Read the text file
    lines = File.readlines(txt_path)

    # Define search terms for our safety standards
    search_terms = [
      # Height categories and user limits
      "1.0m", "1.2m", "1.5m", "1.8m", "height", "user", "capacity",

      # Slide safety
      "slide", "600mm", "3000mm", "6000mm", "containing wall", "runout", "gradient",

      # Anchoring
      "anchor", "1600", "Newton", "pull strength", "ground", "restraint",

      # Materials
      "fabric", "tensile strength", "1850", "tear strength", "350",
      "thread", "88 Newton", "rope", "18mm", "45mm", "netting", "mesh",

      # Electrical
      "blower", "1.0 KPA", "pressure", "finger probe", "8mm", "grounding",

      # Safety requirements
      "evacuation", "30 second", "fall height", "0.6m", "multiple exits", "15 users"
    ]

    found_references = {}

    search_terms.each do |term|
      found_references[term] = []

      lines.each_with_index do |line, index|
        if line.downcase.include?(term.downcase)
          found_references[term] << {
            line_number: index + 1,
            content: line.strip
          }
        end
      end
    end

    # Display results
    found_references.each do |term, matches|
      if matches.any?
        puts "\n🎯 Found #{matches.count} reference(s) for '#{term}':"
        matches.first(3).each do |match| # Show first 3 matches
          puts "   Line #{match[:line_number]}: #{match[:content]}"
        end
        puts "   ... (#{matches.count - 3} more)" if matches.count > 3
      end
    end

    # Summary
    total_matches = found_references.values.flatten.count
    terms_found = found_references.count { |term, matches| matches.any? }

    puts "\n📈 Summary:"
    puts "   Total search terms: #{search_terms.count}"
    puts "   Terms with matches: #{terms_found}"
    puts "   Total matches found: #{total_matches}"

    if terms_found < search_terms.count
      puts "\n⚠️  Terms with no matches:"
      found_references.each do |term, matches|
        puts "   - #{term}" if matches.empty?
      end
    end
  end

  desc "Generate detailed safety standards verification report"
  task generate_verification_report: :environment do
    txt_path = Rails.root.join("tmp/EN_14960-1_2019.txt")
    report_path = Rails.root.join("tmp/safety_standards_verification_report.md")

    unless File.exist?(txt_path)
      puts "❌ Text file not found. Run 'rake safety_standards:download_and_convert' first."
      exit 1
    end

    puts "📝 Generating detailed verification report..."

    lines = File.readlines(txt_path)

    # Our current safety standards from the model
    standards_to_verify = [
      {
        category: "Height Categories",
        standards: [
          "1.0m (Young children)",
          "1.2m (Children)",
          "1.5m (Adolescents)",
          "1.8m (Adults)"
        ]
      },
      {
        category: "Slide Safety Thresholds",
        standards: [
          "Under 600mm - no walls required",
          "600mm-3000mm - basic walls",
          "3000mm-6000mm - enhanced walls (1.25x height)",
          "Over 6000mm - permanent roof required"
        ]
      },
      {
        category: "Material Requirements",
        standards: [
          "Fabric tensile strength: 1850 Newtons minimum",
          "Tear strength: 350 Newtons minimum",
          "Thread tensile strength: 88 Newtons minimum",
          "Rope diameter: 18mm-45mm"
        ]
      },
      {
        category: "Anchoring Requirements",
        standards: [
          "Anchor calculation: ((Area² × 114) ÷ 1600) × 1.5",
          "Pull strength: 1600 Newton minimum"
        ]
      },
      {
        category: "Safety Limits",
        standards: [
          "Maximum evacuation time: 30 seconds",
          "Minimum pressure: 1.0 KPA",
          "Maximum fall height: 0.6m",
          "Multiple exits required for >15 users"
        ]
      }
    ]

    # Generate report
    report_content = "# Safety Standards Verification Report\n\n"
    report_content += "Generated: #{Time.current.strftime("%Y-%m-%d %H:%M:%S")}\n"
    report_content += "Source: EN 14960-1 (2019)\n"
    report_content += "Text file: #{txt_path}\n\n"

    standards_to_verify.each do |category_info|
      report_content += "## #{category_info[:category]}\n\n"

      category_info[:standards].each do |standard|
        report_content += "### #{standard}\n\n"

        # Search for this standard in the text
        relevant_lines = []

        # Extract key search terms from the standard
        search_terms = extract_search_terms(standard)

        search_terms.each do |term|
          lines.each_with_index do |line, index|
            if line.downcase.include?(term.downcase)
              relevant_lines << {
                line_number: index + 1,
                content: line.strip,
                search_term: term
              }
            end
          end
        end

        if relevant_lines.any?
          report_content += "**Found references:**\n\n"
          relevant_lines.uniq { |r| r[:line_number] }.first(5).each do |ref|
            report_content += "- Line #{ref[:line_number]}: #{ref[:content]}\n"
          end
          report_content += "\n"
        else
          report_content += "**⚠️ No direct references found**\n\n"
        end

        report_content += "---\n\n"
      end
    end

    # Write report
    File.write(report_path, report_content)

    puts "✅ Verification report generated: #{report_path}"
    puts "📊 Report contains verification for #{standards_to_verify.sum { |c| c[:standards].count }} standards"
  end

  private

  def extract_search_terms(standard_text)
    # Extract meaningful search terms from standard descriptions
    terms = []

    # Look for numbers with units
    terms += standard_text.scan(/\d+\.?\d*\s*(?:mm|m|KPA|Newton|second|users)/).map(&:strip)

    # Look for key phrases
    key_phrases = [
      "tensile strength", "tear strength", "pull strength", "evacuation time",
      "fall height", "multiple exits", "walls required", "permanent roof",
      "young children", "children", "adolescents", "adults"
    ]

    key_phrases.each do |phrase|
      terms << phrase if standard_text.downcase.include?(phrase.downcase)
    end

    # Look for standalone numbers that might be important
    numbers = standard_text.scan(/\b\d+\.?\d*\b/)
    terms += numbers

    terms.uniq.reject(&:empty?)
  end
end
