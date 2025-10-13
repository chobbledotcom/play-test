# typed: strict
# frozen_string_literal: true

class QrCodeService
  extend T::Sig

  sig { params(record: T.any(Inspection, Unit)).returns(T.nilable(String)) }
  def self.generate_qr_code(record)
    require "rqrcode"

    # Create QR code for the report URL using the shorter format
    if record.is_a?(Inspection)
      generate_inspection_qr_code(record)
    elsif record.is_a?(Unit)
      generate_unit_qr_code(record)
    end
  end

  sig { params(inspection: Inspection).returns(String) }
  def self.generate_inspection_qr_code(inspection)
    require "rqrcode"

    base_url = T.must(Rails.configuration.base_url)
    url = "#{base_url}/inspections/#{inspection.id}"
    generate_qr_code_from_url(url)
  end

  sig { params(unit: Unit).returns(String) }
  def self.generate_unit_qr_code(unit)
    require "rqrcode"

    base_url = T.must(Rails.configuration.base_url)
    url = "#{base_url}/units/#{unit.id}"
    generate_qr_code_from_url(url)
  end

  sig { params(url: String).returns(String) }
  def self.generate_qr_code_from_url(url)
    # Create QR code with optimized options for chunkier appearance
    qrcode = RQRCode::QRCode.new(url, qr_code_options)
    qrcode.as_png(png_options).to_blob
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def self.qr_code_options
    {
      # Use lower error correction level for fewer modules (chunkier code)
      # :l - 7% error correction (lowest, largest modules)
      # :m - 15% error correction
      # :q - 25% error correction
      # :h - 30% error correction (highest, smallest modules)
      level: :m
    }
  end

  sig { returns(T::Hash[Symbol, T.untyped]) }
  def self.png_options
    {
      bit_depth: 1,
      border_modules: 0,           # No border for proper alignment
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 8,           # Larger modules
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 300
    }
  end
end
