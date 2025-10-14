# typed: strict
# frozen_string_literal: true

# Typed configuration for PDF generation settings
# Provides type-safe access to PDF-related configuration values
class PdfConfig < T::Struct
  extend T::Sig

  # Enable PDF caching (based on PDF_CACHE_FROM being set)
  const :cache_enabled, T::Boolean

  # Date from which PDFs should be cached (nil if caching disabled)
  const :cache_from, T.nilable(Date)

  # Whether to redirect to S3 URLs instead of proxying PDFs
  const :redirect_to_s3, T::Boolean

  # Optional logo filename to override user logos (from assets/images/)
  const :logo, T.nilable(String)

  sig { params(env: T::Hash[String, T.nilable(String)]).returns(PdfConfig) }
  def self.from_env(env)
    cache_from_str = env["PDF_CACHE_FROM"]
    cache_date = if cache_from_str&.present?
      Date.parse(cache_from_str)
    end

    new(
      cache_enabled: cache_from_str.present?,
      cache_from: cache_date,
      redirect_to_s3: env["REDIRECT_TO_S3_PDFS"] == "true",
      logo: env["PDF_LOGO"]
    )
  end
end
