# typed: strict

# The simplecov gem ships no RBI and is only required under the test suite
# (Gemfile sets require: false), so Tapioca never sees it and sorbet/rbi/gems
# carries nothing for it. Declare the API the coverage tooling uses
# (lib/simplecov_setup.rb, lib/coverage_ratchet.rb).
module SimpleCov
  extend T::Sig

  # Aggregate statistics for one criterion (lines, branches).
  class CoverageStatistics
    extend T::Sig

    sig { returns(Integer) }
    def covered; end

    sig { returns(Integer) }
    def total; end

    sig { returns(Float) }
    def percent; end
  end

  class Result
    extend T::Sig

    sig { returns(T::Hash[Symbol, CoverageStatistics]) }
    def coverage_statistics; end
  end

  module ResultMerger
    extend T::Sig

    # Returns nil when no resultsets could be read from the given path.
    sig { params(resultset_path: String).returns(T.nilable(Result)) }
    def self.merge_results(resultset_path); end
  end

  # start and configure instance-evaluate their block on the configuration,
  # so the block body is not type-checked here.
  sig { params(profile: T.nilable(String), block: T.proc.void).void }
  def self.start(profile = nil, &block); end

  sig { params(profile_name: String).void }
  def self.load_profile(profile_name); end

  sig { params(block: T.proc.void).void }
  def self.configure(&block); end
end
