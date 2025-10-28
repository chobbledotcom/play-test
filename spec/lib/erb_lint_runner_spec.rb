# typed: false
# frozen_string_literal: true

require "rails_helper"
require "erb_lint_runner"

RSpec.describe ErbLintRunner do
  let(:runner) { described_class.new }
  let(:autocorrect_runner) { described_class.new(autocorrect: true) }
  let(:verbose_runner) { described_class.new(verbose: true) }

  describe "#initialize" do
    it "uses default values when no parameters are provided" do
      expect(runner.instance_variable_get(:@autocorrect)).to be false
      expect(runner.instance_variable_get(:@verbose)).to be false
      expect(runner.instance_variable_get(:@processed)).to eq(0)
      expect(runner.instance_variable_get(:@total_violations)).to eq(0)
      expect(runner.instance_variable_get(:@failed_files)).to eq([])
    end

    it "accepts autocorrect parameter" do
      expect(autocorrect_runner.instance_variable_get(:@autocorrect)).to be true
      expect(autocorrect_runner.instance_variable_get(:@verbose)).to be false
    end

    it "accepts verbose parameter" do
      expect(verbose_runner.instance_variable_get(:@verbose)).to be true
      expect(verbose_runner.instance_variable_get(:@autocorrect)).to be false
    end

    it "accepts both parameters" do
      combined_runner = described_class.new(autocorrect: true, verbose: true)
      expect(combined_runner.instance_variable_get(:@autocorrect)).to be true
      expect(combined_runner.instance_variable_get(:@verbose)).to be true
    end
  end

  describe "#run_on_all_files" do
    let(:erb_files) { ["app/views/users/index.html.erb", "app/views/users/show.erb"] }

    before do
      allow(runner).to receive(:find_erb_files).and_return(erb_files)
      allow(runner).to receive(:process_file)
      allow(runner).to receive(:print_summary)
      allow(runner).to receive(:puts)
      allow(runner.instance_variable_get(:@failed_files)).to receive(:empty?).and_return(true)
    end

    it "finds all ERB files" do
      expect(runner).to receive(:find_erb_files).and_return(erb_files)
      runner.run_on_all_files
    end

    it "processes each file with correct index" do
      expect(runner).to receive(:process_file).with("app/views/users/index.html.erb", 1, 2)
      expect(runner).to receive(:process_file).with("app/views/users/show.erb", 2, 2)
      runner.run_on_all_files
    end

    it "prints initial status message" do
      expect(runner).to receive(:puts).with("Found 2 ERB files to lint...")
      expect(runner).to receive(:puts).with("=" * 80)
      runner.run_on_all_files
    end

    it "prints summary after processing" do
      expect(runner).to receive(:print_summary)
      runner.run_on_all_files
    end

    context "when all files pass" do
      it "returns true" do
        allow(runner.instance_variable_get(:@failed_files)).to receive(:empty?).and_return(true)
        expect(runner.run_on_all_files).to be true
      end
    end

    context "when some files fail" do
      it "returns false" do
        allow(runner.instance_variable_get(:@failed_files)).to receive(:empty?).and_return(false)
        expect(runner.run_on_all_files).to be false
      end
    end
  end

  describe "#run_on_files" do
    let(:files) { ["app/views/users/edit.erb", "app/views/posts/new.html.erb"] }

    before do
      allow(runner).to receive(:process_file)
      allow(runner).to receive(:print_summary)
      allow(runner).to receive(:puts)
      allow(runner.instance_variable_get(:@failed_files)).to receive(:empty?).and_return(true)
    end

    it "processes provided files" do
      expect(runner).to receive(:process_file).with("app/views/users/edit.erb", 1, 2)
      expect(runner).to receive(:process_file).with("app/views/posts/new.html.erb", 2, 2)
      runner.run_on_files(files)
    end

    it "prints initial status message" do
      expect(runner).to receive(:puts).with("Linting 2 ERB files...")
      expect(runner).to receive(:puts).with("=" * 80)
      runner.run_on_files(files)
    end

    it "prints summary after processing" do
      expect(runner).to receive(:print_summary)
      runner.run_on_files(files)
    end

    context "when all files pass" do
      it "returns true" do
        allow(runner.instance_variable_get(:@failed_files)).to receive(:empty?).and_return(true)
        expect(runner.run_on_files(files)).to be true
      end
    end

    context "when some files fail" do
      it "returns false" do
        allow(runner.instance_variable_get(:@failed_files)).to receive(:empty?).and_return(false)
        expect(runner.run_on_files(files)).to be false
      end
    end
  end

  describe "#find_erb_files (private)" do
    let(:test_files) do
      [
        "app/views/users/index.html.erb",
        "app/views/users/show.erb",
        "vendor/bundle/gems/some_gem/view.erb",
        "node_modules/package/template.erb",
        "tmp/cache/template.erb",
        "public/assets/template.erb",
        "app/views/posts/index.html.erb"
      ]
    end

    before do
      allow(Dir).to receive(:glob).and_return([])

      # Mock first pattern (*.erb)
      allow(Dir).to receive(:glob).with(Rails.root.join("**/*.erb").to_s).and_return([
        Rails.root.join("app/views/users/show.erb").to_s,
        Rails.root.join("vendor/bundle/gems/some_gem/view.erb").to_s,
        Rails.root.join("node_modules/package/template.erb").to_s,
        Rails.root.join("tmp/cache/template.erb").to_s,
        Rails.public_path.join("assets/template.erb").to_s
      ])

      # Mock second pattern (*.html.erb)
      allow(Dir).to receive(:glob).with(Rails.root.join("**/*.html.erb").to_s).and_return([
        Rails.root.join("app/views/users/index.html.erb").to_s,
        Rails.root.join("app/views/posts/index.html.erb").to_s
      ])
    end

    it "finds ERB files with both patterns" do
      files = runner.send(:find_erb_files)
      expect(files).to include("app/views/users/index.html.erb")
      expect(files).to include("app/views/users/show.erb")
      expect(files).to include("app/views/posts/index.html.erb")
    end

    it "excludes vendor directory" do
      files = runner.send(:find_erb_files)
      expect(files).not_to include("vendor/bundle/gems/some_gem/view.erb")
    end

    it "excludes node_modules directory" do
      files = runner.send(:find_erb_files)
      expect(files).not_to include("node_modules/package/template.erb")
    end

    it "excludes tmp directory" do
      files = runner.send(:find_erb_files)
      expect(files).not_to include("tmp/cache/template.erb")
    end

    it "excludes public directory" do
      files = runner.send(:find_erb_files)
      expect(files).not_to include("public/assets/template.erb")
    end

    it "returns unique sorted files" do
      files = runner.send(:find_erb_files)
      expect(files).to eq(files.uniq.sort)
    end
  end

  describe "#process_file (private)" do
    let(:file) { "app/views/users/index.html.erb" }
    let(:status) { instance_double(Process::Status, success?: true) }

    before do
      allow(runner).to receive(:print)
      allow(runner).to receive(:puts)
      allow($stdout).to receive(:flush)
      allow(Time).to receive(:now).and_return(1000.0, 1002.5) # 2.5 second duration
    end

    context "when erb_lint succeeds" do
      before do
        allow(Open3).to receive(:capture2e).and_return(["", status])
      end

      it "runs erb_lint with correct arguments" do
        expect(Open3).to receive(:capture2e).with("bundle", "exec", "erb_lint", file)
        runner.send(:process_file, file, 1, 10)
      end

      it "runs erb_lint with autocorrect when enabled" do
        expect(Open3).to receive(:capture2e).with("bundle", "exec", "erb_lint", file, "--autocorrect")
        autocorrect_runner.send(:process_file, file, 1, 10)
      end

      it "prints progress information" do
        expect(runner).to receive(:print).with("[1/10] #{file.ljust(60)} ")
        runner.send(:process_file, file, 1, 10)
      end

      it "prints success message" do
        expect(runner).to receive(:puts).with("✅")
        runner.send(:process_file, file, 1, 10)
      end

      it "increments processed counter" do
        runner.send(:process_file, file, 1, 10)
        expect(runner.instance_variable_get(:@processed)).to eq(1)
      end

      it "does not add to failed files" do
        runner.send(:process_file, file, 1, 10)
        expect(runner.instance_variable_get(:@failed_files)).to be_empty
      end
    end

    context "when erb_lint fails" do
      let(:status) { instance_double(Process::Status, success?: false) }
      let(:output) { "3 error(s) were found in the file" }

      before do
        allow(Open3).to receive(:capture2e).and_return([output, status])
      end

      it "extracts violation count from output" do
        expect(runner).to receive(:extract_violation_count).with(output).and_call_original
        runner.send(:process_file, file, 1, 10)
      end

      it "increments total violations" do
        runner.send(:process_file, file, 1, 10)
        expect(runner.instance_variable_get(:@total_violations)).to eq(3)
      end

      it "adds to failed files" do
        runner.send(:process_file, file, 1, 10)
        failed_files = runner.instance_variable_get(:@failed_files)
        expect(failed_files).to include(
          hash_including(file: file, violations: 3, output: output)
        )
      end

      context "when processing is fast" do
        before do
          allow(Time).to receive(:now).and_return(1000.0, 1001.5) # 1.5 second duration
        end

        it "prints failure message without slow warning" do
          expect(runner).to receive(:puts).with("❌ 3 violation(s)")
          runner.send(:process_file, file, 1, 10)
        end
      end

      context "when processing is slow" do
        let(:output) do
          <<~OUTPUT
            3 error(s) were found in the file
              10:5  Error message 1
              20:10 Error message 2
              30:15 Error message 3
              40:20 Error message 4
          OUTPUT
        end

        before do
          allow(Time).to receive(:now).and_return(1000.0, 1006.0) # 6 second duration
          allow(Open3).to receive(:capture2e).and_return([output, status])
        end

        it "prints failure message with slow warning" do
          expect(runner).to receive(:puts).with("❌ 3 violation(s) ⚠️  SLOW")
          runner.send(:process_file, file, 1, 10)
        end

        context "in verbose mode" do
          it "prints slow file details" do
            expect(verbose_runner).to receive(:puts).with("❌ 3 violation(s) ⚠️  SLOW").ordered
            expect(verbose_runner).to receive(:puts).with("  Slow file details:").ordered
            expect(verbose_runner).to receive(:puts).with(["    10:5  Error message 1", "    20:10 Error message 2", "    30:15 Error message 3"]).ordered
            verbose_runner.send(:process_file, file, 1, 10)
          end
        end
      end
    end

    context "when an exception occurs" do
      before do
        allow(Open3).to receive(:capture2e).and_raise(StandardError.new("Command failed"))
      end

      it "handles the exception gracefully" do
        expect { runner.send(:process_file, file, 1, 10) }.not_to raise_error
      end

      it "prints error message" do
        expect(runner).to receive(:puts).with("💥 Error: Command failed")
        runner.send(:process_file, file, 1, 10)
      end

      it "adds to failed files with error message" do
        runner.send(:process_file, file, 1, 10)
        failed_files = runner.instance_variable_get(:@failed_files)
        expect(failed_files).to include(
          hash_including(file: file, violations: 0, output: "Command failed")
        )
      end
    end
  end

  describe "#extract_violation_count (private)" do
    it "extracts count from standard erb_lint output" do
      output = "1 error(s) were found in the file"
      expect(runner.send(:extract_violation_count, output)).to eq(1)
    end

    it "extracts count with multiple errors" do
      output = "5 error(s) were found in the file"
      expect(runner.send(:extract_violation_count, output)).to eq(5)
    end

    it "returns 1 when no match found" do
      output = "Some other error message"
      expect(runner.send(:extract_violation_count, output)).to eq(1)
    end

    it "handles multi-line output" do
      output = <<~OUTPUT
        Linting file.erb
        Some warnings here
        3 error(s) were found in the file
        Additional information
      OUTPUT
      expect(runner.send(:extract_violation_count, output)).to eq(3)
    end
  end

  describe "#print_summary (private)" do
    before do
      allow(runner).to receive(:puts)
    end

    context "with no failures" do
      before do
        runner.instance_variable_set(:@processed, 10)
        runner.instance_variable_set(:@failed_files, [])
        runner.instance_variable_set(:@total_violations, 0)
      end

      it "prints success summary" do
        expect(runner).to receive(:puts).with("=" * 80)
        expect(runner).to receive(:puts).with("\nSUMMARY:")
        expect(runner).to receive(:puts).with("Processed: 10 files")
        expect(runner).to receive(:puts).with("Failed: 0 files")
        expect(runner).to receive(:puts).with("Total violations: 0")
        expect(runner).to receive(:puts).with("\n✅ All ERB files passed linting!")

        runner.send(:print_summary)
      end
    end

    context "with failures" do
      let(:failed_files) do
        [
          {file: "app/views/users/index.erb", violations: 3, output: "output1"},
          {file: "app/views/posts/show.erb", violations: 2, output: "output2"}
        ]
      end

      before do
        runner.instance_variable_set(:@processed, 10)
        runner.instance_variable_set(:@failed_files, failed_files)
        runner.instance_variable_set(:@total_violations, 5)
      end

      it "prints failure summary" do
        expect(runner).to receive(:puts).with("=" * 80)
        expect(runner).to receive(:puts).with("\nSUMMARY:")
        expect(runner).to receive(:puts).with("Processed: 10 files")
        expect(runner).to receive(:puts).with("Failed: 2 files")
        expect(runner).to receive(:puts).with("Total violations: 5")
        expect(runner).to receive(:puts).with("\nFailed files:")
        expect(runner).to receive(:puts).with("  app/views/users/index.erb (3 violation(s))")
        expect(runner).to receive(:puts).with("  app/views/posts/show.erb (2 violation(s))")

        runner.send(:print_summary)
      end

      context "without autocorrect" do
        it "shows fix command" do
          expect(runner).to receive(:puts).with("\nTo fix these issues, run:")
          expect(runner).to receive(:puts).with("  rake code_standards:erb_lint_fix")

          runner.send(:print_summary)
        end
      end

      context "with autocorrect" do
        it "does not show fix command" do
          expect(autocorrect_runner).not_to receive(:puts).with("\nTo fix these issues, run:")
          expect(autocorrect_runner).not_to receive(:puts).with("  rake code_standards:erb_lint_fix")

          autocorrect_runner.instance_variable_set(:@processed, 10)
          autocorrect_runner.instance_variable_set(:@failed_files, failed_files)
          autocorrect_runner.instance_variable_set(:@total_violations, 5)

          autocorrect_runner.send(:print_summary)
        end
      end
    end
  end

  describe "integration tests" do
    context "full workflow" do
      let(:erb_files) { ["app/views/test1.erb", "app/views/test2.erb"] }
      let(:success_status) { instance_double(Process::Status, success?: true) }
      let(:failure_status) { instance_double(Process::Status, success?: false) }

      before do
        allow(runner).to receive(:find_erb_files).and_return(erb_files)
        allow(runner).to receive(:puts)
        allow(runner).to receive(:print)
        allow($stdout).to receive(:flush)
        allow(Time).to receive(:now).and_return(1000.0, 1001.0, 1002.0, 1003.0)
      end

      it "processes mixed success and failure files correctly" do
        allow(Open3).to receive(:capture2e).with("bundle", "exec", "erb_lint", "app/views/test1.erb")
          .and_return(["", success_status])
        allow(Open3).to receive(:capture2e).with("bundle", "exec", "erb_lint", "app/views/test2.erb")
          .and_return(["2 error(s) were found", failure_status])

        result = runner.run_on_all_files

        expect(result).to be false
        expect(runner.instance_variable_get(:@processed)).to eq(2)
        expect(runner.instance_variable_get(:@total_violations)).to eq(2)
        expect(runner.instance_variable_get(:@failed_files).length).to eq(1)
      end

      it "returns true when all files pass" do
        allow(Open3).to receive(:capture2e).and_return(["", success_status])

        result = runner.run_on_all_files

        expect(result).to be true
        expect(runner.instance_variable_get(:@processed)).to eq(2)
        expect(runner.instance_variable_get(:@total_violations)).to eq(0)
        expect(runner.instance_variable_get(:@failed_files)).to be_empty
      end
    end
  end
end
