# typed: strict
# frozen_string_literal: true

class PdfPerformance
  extend T::Sig

  EVENT = "pdf.performance"

  class << self
    extend T::Sig

    sig do
      params(
        stage: Symbol,
        pdf_type: Symbol,
        record_id: T.untyped,
        metadata: T.untyped,
        block: T.proc.returns(T.untyped)
      ).returns(T.untyped)
    end
    def measure(stage, pdf_type:, record_id:, **metadata, &block)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      block.call
    ensure
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      Rails.logger.info({
        event: EVENT,
        stage: stage,
        pdf_type: pdf_type,
        record_id: record_id,
        duration_ms: (duration * 1000).round(1),
        **metadata
      })
    end
  end
end
