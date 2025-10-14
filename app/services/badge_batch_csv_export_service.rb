# typed: true
# frozen_string_literal: true

class BadgeBatchCsvExportService
  extend T::Sig

  sig { params(badge_batch: BadgeBatch).void }
  def initialize(badge_batch)
    @badge_batch = badge_batch
  end

  sig { returns(String) }
  def generate
    CSV.generate(headers: true) do |csv|
      csv << headers

      @badge_batch.badges.includes(:unit).order(:id).each do |badge|
        csv << row_for_badge(badge)
      end
    end
  end

  private

  sig { returns(T::Array[String]) }
  def headers
    [
      "Badge ID",
      "Batch Creation Date",
      "Batch Notes",
      "Badge Notes",
      "Used",
      "URL"
    ]
  end

  sig { params(badge: Badge).returns(T::Array[String]) }
  def row_for_badge(badge)
    batch_creation_date = @badge_batch.created_at.strftime("%Y-%m-%d %H:%M:%S")

    [
      badge.id,
      batch_creation_date,
      @badge_batch.note || "",
      badge.note || "",
      badge.unit.present?.to_s,
      unit_url(badge.id)
    ]
  end

  sig { params(badge_id: String).returns(String) }
  def unit_url(badge_id)
    "#{base_url}/units/#{badge_id}.pdf"
  end

  sig { returns(String) }
  def base_url
    Rails.configuration.app.base_url
  end
end
