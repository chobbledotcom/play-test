# typed: false
# frozen_string_literal: true

# Ensure SQLite databases use WAL (Write-Ahead Logging) mode
# This is required for Litestream replication to work properly
#
# WAL mode allows concurrent readers while a write is in progress,
# and is necessary for Litestream to track database changes.

Rails.application.config.after_initialize do
  ActiveRecord::Base.connection_pool.with_connection do |conn|
    next unless conn.adapter_name == "SQLite"

    # Check current journal mode
    result = conn.execute("PRAGMA journal_mode")
    current_mode = result.first["journal_mode"]

    # Enable WAL mode if not already enabled
    if current_mode != "wal"
      conn.execute("PRAGMA journal_mode=WAL")
      Rails.logger.info("SQLite: Enabled WAL mode")
    end

    # Set recommended pragmas for WAL mode
    conn.execute("PRAGMA busy_timeout=5000")
    conn.execute("PRAGMA synchronous=NORMAL")
  end

  # Also configure queue database if using multiple databases
  env_configs = ActiveRecord::Base.configurations.configs_for(
    env_name: Rails.env
  )

  if env_configs.count > 1
    ActiveRecord::Base.connected_to(role: :writing, shard: :queue) do
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        next unless conn.adapter_name == "SQLite"

        result = conn.execute("PRAGMA journal_mode")
        current_mode = result.first["journal_mode"]

        if current_mode != "wal"
          conn.execute("PRAGMA journal_mode=WAL")
          Rails.logger.info("SQLite Queue: Enabled WAL mode")
        end

        conn.execute("PRAGMA busy_timeout=5000")
        conn.execute("PRAGMA synchronous=NORMAL")
      end
    end
  end
rescue ActiveRecord::NoDatabaseError
  # Database doesn't exist yet, will be created with WAL mode
  nil
end
