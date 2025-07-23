class PdfGeneratorService
  module Configuration
    # Unit table constants
    UNIT_LABEL_COLUMN_WIDTH = 100
    UNIT_NAME_MAX_LENGTH = 30
    UNIT_TABLE_CELL_PADDING = [6, 4]
    UNIT_TABLE_TEXT_SIZE = 9

    # General text and spacing constants
    HEADER_TEXT_SIZE = 12
    HEADER_SPACING = 8
    STATUS_TEXT_SIZE = 14
    STATUS_SPACING = 15
    SECTION_TITLE_SIZE = 14
    COMMENTS_PADDING = 20

    # Header table constants
    LOGO_HEIGHT = 50
    HEADER_TABLE_PADDING = [5, 0]
    LOGO_COLUMN_WIDTH_RATIO = 1.0 / 3.0

    # Table constants
    TABLE_CELL_PADDING = [5, 10]
    TABLE_FIRST_COLUMN_WIDTH = 150
    NICE_TABLE_CELL_PADDING = [4, 8]
    NICE_TABLE_TEXT_SIZE = 10

    # Inspection history table styling
    HISTORY_TABLE_TEXT_SIZE = 8
    HISTORY_TABLE_HEADER_COLOR = "F5F5F5"
    HISTORY_TABLE_ROW_COLOR = "FAFAFA"
    HISTORY_TABLE_ALT_ROW_COLOR = "F0F0F0"
    PASS_COLOR = "008000"  # Green
    FAIL_COLOR = "CC0000"  # Red
    NA_COLOR = "4169E1"  # Royal Blue
    HEADER_COLOR = "663399"  # Purple
    SUBTITLE_COLOR = "666666"  # Gray

    # Inspection history table column widths
    HISTORY_DATE_COLUMN_WIDTH = 90      # Date column (DD/MM/YYYY) - slightly wider
    HISTORY_RESULT_COLUMN_WIDTH = 45    # Result column (PASS/FAIL) - narrower
    HISTORY_INSPECTOR_WIDTH_PERCENT = 0.5  # 50% of remaining space
    HISTORY_LOCATION_WIDTH_PERCENT = 0.5   # 50% of remaining space

    # Assessment layout constants
    ASSESSMENT_COLUMNS_COUNT = 3
    ASSESSMENT_COLUMN_SPACER = 10
    ASSESSMENT_TITLE_SIZE = 10
    ASSESSMENT_FIELD_TEXT_SIZE = 7
    ASSESSMENT_BLOCK_SPACING = 8

    # QR Code constants
    QR_CODE_SIZE = 80
    QR_CODE_MARGIN = 0  # No margin - align with table right edge
    QR_CODE_BOTTOM_OFFSET = HEADER_SPACING  # Match header spacing from top

    # Unit photo constants
    UNIT_PHOTO_X_OFFSET = 130
    UNIT_PHOTO_WIDTH = 120
    UNIT_PHOTO_HEIGHT = 90

    # Watermark constants
    WATERMARK_TRANSPARENCY = 0.4
    WATERMARK_TEXT_SIZE = 24
    WATERMARK_WIDTH = 100
    WATERMARK_HEIGHT = 60

    # Photos page constants
    PHOTO_MAX_HEIGHT_PERCENT = 0.25  # 25% of page height
    PHOTO_SPACING = 20  # Space between photos
    PHOTO_LABEL_SIZE = 10  # Size of "Photo 1", "Photo 2", "Photo 3" text
    PHOTO_LABEL_SPACING = 5  # Space between photo and label

    def self.setup_pdf_fonts(pdf)
      font_path = Rails.root.join("app/assets/fonts")
      pdf.font_families.update(
        "NotoSans" => {
          normal: "#{font_path}/NotoSans-Regular.ttf",
          bold: "#{font_path}/NotoSans-Bold.ttf",
          italic: "#{font_path}/NotoSans-Regular.ttf",
          bold_italic: "#{font_path}/NotoSans-Bold.ttf"
        },
        "NotoEmoji" => {
          normal: "#{font_path}/NotoEmoji-Regular.ttf"
        }
      )
      pdf.font "NotoSans"
    end
  end
end
