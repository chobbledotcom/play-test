# typed: strict
# frozen_string_literal: true

module MagicContainer
  # Everything the wizard collected before executing the deployment.
  class Answers < T::Struct
    const :archive_path, Pathname
    const :access_key, String
    const :app_name, String
    const :region, String
    const :runtime_type, String
    const :registry_id, String
    const :image_ref, String
    const :image_tag, String
    const :storage_s3, S3Details
    const :litestream_s3, S3Details
    const :display_app_name, String
    const :base_url, String
    const :rails_master_key, String
    const :sentry_dsn, String
    const :secret_key_base, String
    # The Bunny app id once an attempt got as far as creating it, so a retried
    # attempt reuses the app instead of creating a duplicate.
    const :app_id, T.nilable(String), default: nil
    # A fingerprint of the archive the seeded replica paths below were
    # pushed from, so a backup regenerated at the recorded path cannot
    # inherit the previous contents' seeding progress.
    const :archive_digest, T.nilable(String), default: nil
    # Replica paths this attempt has already pushed to Litestream, so a retry
    # skips only work this answers lineage performed - never data some other
    # deployment left in the replica.
    const :seeded_replica_paths, T::Array[String], default: []
  end
end
