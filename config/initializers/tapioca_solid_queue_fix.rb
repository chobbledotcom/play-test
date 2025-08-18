# typed: false
# frozen_string_literal: true

# Fix for Tapioca loading issue with SolidQueue
# Only apply this fix when running Tapioca commands
if defined?(Tapioca) || ENV["RUNNING_TAPIOCA"] == "true"
  # Load SolidQueue and its adapter before Rails tries to set it
  require "solid_queue"
  require "active_job/queue_adapters/solid_queue_adapter"

  # Alternatively, change the queue adapter to test mode for Tapioca
  if defined?(Rails) && Rails.application
    Rails.application.configure do
      config.active_job.queue_adapter = :test
    end
  end
end
