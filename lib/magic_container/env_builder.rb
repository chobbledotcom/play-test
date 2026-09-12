# typed: strict
# frozen_string_literal: true

module MagicContainer
  # Builds the environment variables the Magic Container needs at runtime:
  # everything the app needs to serve from S3 and restore its databases
  # from Litestream on first boot.
  class EnvBuilder
    extend T::Sig

    sig { params(answers: Answers).returns(T::Array[[String, String]]) }
    def self.build(answers)
      required(answers).merge(optional(answers)).sort
    end

    sig { params(answers: Answers).returns(T::Hash[String, String]) }
    def self.required(answers)
      storage = answers.storage_s3
      litestream = answers.litestream_s3
      {
        "LITESTREAM_ACCESS_KEY_ID" => litestream.access_key_id,
        "LITESTREAM_ENABLED" => "true",
        "LITESTREAM_S3_BUCKET" => litestream.bucket,
        "LITESTREAM_S3_ENDPOINT" => litestream.endpoint,
        "LITESTREAM_S3_REGION" => litestream.region,
        "LITESTREAM_SECRET_ACCESS_KEY" => litestream.secret_access_key,
        "S3_ACCESS_KEY_ID" => storage.access_key_id,
        "S3_BUCKET" => storage.bucket,
        "S3_ENDPOINT" => storage.endpoint,
        "S3_REGION" => storage.region,
        "S3_SECRET_ACCESS_KEY" => storage.secret_access_key,
        "SECRET_KEY_BASE" => answers.secret_key_base,
        "USE_S3_STORAGE" => "true"
      }
    end

    sig { params(answers: Answers).returns(T::Hash[String, String]) }
    def self.optional(answers)
      env = {}
      app_name = answers.display_app_name
      env["APP_NAME"] = app_name if app_name.present?
      env["BASE_URL"] = answers.base_url if answers.base_url.present?
      master_key = answers.rails_master_key
      env["RAILS_MASTER_KEY"] = master_key if master_key.present?
      env["SENTRY_DSN"] = answers.sentry_dsn if answers.sentry_dsn.present?
      env
    end
  end
end
