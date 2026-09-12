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
    const :volume, T::Boolean
    const :volume_size_gb, Integer
    const :storage_s3, S3Details
    const :litestream_s3, S3Details
    const :display_app_name, String
    const :base_url, String
    const :rails_master_key, String
    const :sentry_dsn, String
    const :secret_key_base, String
  end
end
