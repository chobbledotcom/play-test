# typed: false
# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageRatchet do
  subject(:verify) { described_class.verify(resultset_path: resultset_path) }

  around do |example|
    Dir.mktmpdir("coverage_ratchet", Rails.root.join("tmp")) do |dir|
      @dir = dir
      @resultset_path = File.join(dir, ".resultset.json")
      File.write(tracked_file, "# a tracked file\n\ndef value\n  1\nend\n")
      example.run
    end
  end

  let(:resultset_path) { @resultset_path }

  def tracked_file
    File.join(@dir, "widget.rb")
  end

  def write_resultset(commands)
    File.write(resultset_path, JSON.generate(commands))
  end

  # A resultset entry as a parallel worker writes it: one command with its own
  # slice of line and branch coverage. Branch keys mirror the stringified
  # tuple form Coverage emits after a JSON round-trip.
  def worker(lines:, branches: nil, timestamp: Time.now.to_i)
    file_data = {"lines" => lines}
    file_data["branches"] = branches if branches

    {"RSpec-1" =>
      {"coverage" => {tracked_file => file_data}, "timestamp" => timestamp}}
  end

  def condition(then_hits:, else_hits:)
    {"[:if, 0, 1, 0, 3, 3]" =>
      {"[:then, 1, 2, 0, 2, 8]" => then_hits, "[:else, 2, 3, 0, 3, 8]" => else_hits}}
  end

  it "merges every worker's slice and passes when both criteria meet the ratchet" do
    write_resultset(worker(lines: [1, 1, 0, 1],
      branches: condition(then_hits: 1, else_hits: 0)).merge(
      "RSpec-2" => worker(lines: [nil, nil, 3, nil],
        branches: condition(then_hits: 0, else_hits: 3)).fetch("RSpec-1")
    ))

    expect { verify }.to output(<<~OUTPUT).to_stdout
      Merged line coverage: 4/4 (100.0%)
      Merged branch coverage: 2/2 (100.0%)
      Ratchet: 90% lines, 72% branches
    OUTPUT
  end

  it "covers a line when any worker covered it and skips lines no worker ran" do
    write_resultset(
      "RSpec-1" => worker(lines: [1, 0, nil], branches: condition(then_hits: 1, else_hits: 1)).fetch("RSpec-1"),
      "RSpec-2" => worker(lines: [nil, 2, nil]).fetch("RSpec-1")
    )

    expect { verify }
      .to output(/Merged line coverage: 2\/2/).to_stdout
  end

  it "exits nonzero below the line ratchet" do
    write_resultset(worker(lines: [1, 0, 0, 0], branches: condition(then_hits: 1, else_hits: 1)))

    expect { verify }
      .to raise_error(SystemExit, /Coverage below the baseline ratchet: 25.0% lines/) do |exit_status|
        expect(exit_status.status).to eq(1)
      end
  end

  it "exits nonzero below the branch ratchet" do
    write_resultset(worker(lines: [1, 1], branches: condition(then_hits: 0, else_hits: 0)))

    expect { verify }
      .to raise_error(SystemExit, /0.0% branches \(minimum #{described_class::BRANCH_MINIMUM}%\)/o)
  end

  it "ignores entries older than merge_timeout instead of counting stale coverage" do
    write_resultset(
      "RSpec-1" => worker(lines: [1, 0, 0, 0],
        branches: condition(then_hits: 1, else_hits: 1)).fetch("RSpec-1"),
      "RSpec-2" => worker(lines: [1, 1, 1, 1],
        branches: condition(then_hits: 1, else_hits: 1), timestamp: 2.days.ago.to_i).fetch("RSpec-1")
    )

    expect { verify }.to raise_error(SystemExit, /25.0% lines/)
  end

  it "fails closed on a resultset without branch data instead of a vacuous 100%" do
    write_resultset(worker(lines: [1, 1]))

    expect { verify }
      .to raise_error(SystemExit, /no branch coverage data found in the resultset/)
  end

  it "fails closed when the resultset is missing" do
    expect { verify }.to raise_error(SystemExit, /resultset.json not found/)
  end

  it "fails closed when the resultset holds no coverage data" do
    write_resultset({})

    expect { verify }.to raise_error(SystemExit, /No coverage data found/)
  end
end
