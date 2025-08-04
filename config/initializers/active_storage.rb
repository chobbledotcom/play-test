# frozen_string_literal: true

# Configure Active Storage image processing
# Use ImageMagick in CI environment where libvips might not be available
if ENV["CI"].present?
  Rails.application.config.active_storage.variant_processor = :mini_magick
else
  # Use vips in development/production for better performance
  Rails.application.config.active_storage.variant_processor = :vips
  require "ruby-vips"
end
