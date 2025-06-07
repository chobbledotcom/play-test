# RPII Utility - PDF Generation Documentation

## Overview

The RPII Utility generates comprehensive PDF inspection reports using the PDFsharp library. The PDF contains all inspection data, measurements, safety assessments, and images formatted into a professional single-page report.

## PDF Generation Workflow

### Entry Point

**Method**: `createPDFCert()`
**Location**: Form1.cs:1122
**Trigger**: "Create PDF Report" button click

### Prerequisites

- **Required**: Unique report number must be present
- **Validation**: If `uniquereportNum.Text.Length == 0`, shows error: "Save inspection to database to generate unique report number first."

### Generation Process

1. **Document Creation**: Create PdfDocument with metadata
2. **Page Setup**: Single A4 page layout
3. **Graphics Context**: Initialize XGraphics for drawing
4. **Font Definition**: Set up typography hierarchy
5. **Content Rendering**: Draw all sections sequentially
6. **Image Processing**: Include compressed photos
7. **File Save**: Auto-save with timestamp to Documents folder
8. **Cleanup**: Clear form fields after generation

---

## Document Structure

### PDF Metadata

```csharp
document.Info.Title = "Inflatable Report - Issued by " + InspectionCompName.Text;
document.Info.Creator = InspectionCompName.Text;
document.Info.Author = InspectionCompName.Text;
```

### Page Configuration

- **Size**: A4 (595.28 × 841.89 points)
- **Orientation**: Portrait
- **Margins**: 15 points from edges
- **Layout**: Two-column design with images

---

## Typography System

### Font Hierarchy

| Font Variable     | Font Family | Size | Style   | Usage                        |
| ----------------- | ----------- | ---- | ------- | ---------------------------- |
| `h1font`          | Verdana     | 14pt | Bold    | Main headings, critical info |
| `h2font`          | Arial       | 12pt | Bold    | Section headers              |
| `regularFont`     | Arial       | 8pt  | Regular | Standard content             |
| `regularFontBold` | Arial       | 8pt  | Bold    | Important labels             |
| `smallFont`       | Arial       | 6pt  | Regular | Footer, compact text         |

### Font Usage Examples

```csharp
// Main heading
gfx.DrawString("RPII Inspector Issued Report", h1font, XBrushes.Red, 15, 25);

// Section header
gfx.DrawString("Unit Details", h2font, XBrushes.Black, 15, 130);

// Regular content
gfx.DrawString("Description: " + text, regularFont, XBrushes.Black, 15, 140);
```

---

## Color Scheme

### Color Usage

| Color                    | Usage                         | Context                           |
| ------------------------ | ----------------------------- | --------------------------------- |
| `XBrushes.Red`           | Critical information, headers | Company name, dates, registration |
| `XBrushes.Green`         | Passed inspection result      | Final approval status             |
| `XBrushes.Black`         | Standard text content         | All measurements and data         |
| `XBrushes.SeaShell`      | Background accent             | Author credit box                 |
| `XBrushes.LavenderBlush` | Background accent             | Testimony section                 |

### Dynamic Color Logic

```csharp
// Pass/Fail result coloring
if (passedRadio.Checked == false)
{
    gfx.DrawString("Failed Inspection", h1font, XBrushes.Red, 74, 836);
}
else
{
    gfx.DrawString("Passed Inspection", h1font, XBrushes.Green, 74, 836);
}
```

---

## Layout Structure

### Two-Column Design

#### Left Column (X: 15)

- **Header Information**: Company, dates, registration
- **Unit Details**: Specifications and measurements
- **Height/Count Data**: User capacity information
- **Slide Measurements**: Platform and wall heights
- **Structure Assessments**: Safety checks

#### Right Column (X: 312.5)

- **Structure Continued**: Additional safety checks
- **Anchorage System**: Anchor assessments
- **Totally Enclosed**: Exit requirements
- **Materials**: Fabric and component checks
- **Fan/Blower**: Electrical safety

#### Image Positions

- **Unit Photo**: X: 455, Y: 15 (Top right)
- **Inspector Logo**: X: 315, Y: 15 (Center right)

---

## Content Sections

### 1. Header Section (Y: 15-100)

**Purpose**: Identification and authority information

```csharp
gfx.DrawString("RPII Inspector Issued Report", h1font, XBrushes.Red, 15, 25);
gfx.DrawString("Issued by: " + company, h2font, XBrushes.Black, 15, 40);
gfx.DrawString("Issued " + date, h1font, XBrushes.Red, 15, 55);
gfx.DrawString("RPII Reg Number: " + regNumber, h1font, XBrushes.Red, 15, 70);
gfx.DrawString("Place of Inspection: " + location, regularFontBold, XBrushes.Red, 15, 85);
gfx.DrawString("Unique Report Number: " + reportNum, h2font, XBrushes.Red, 15, 100);
```

### 2. Unit Details Section (Y: 130-190)

**Purpose**: Equipment identification and specifications

```csharp
gfx.DrawString("Unit Details", h2font, XBrushes.Black, 15, 130);
gfx.DrawString("Description: " + description, regularFont, XBrushes.Black, 15, 140);
gfx.DrawString("Manufacturer: " + manufacturer, regularFont, XBrushes.Black, 15, 148);
gfx.DrawString("Size (m): Width: " + width + " Length: " + length + " Height: " + height, regularFont, XBrushes.Black, 15, 156);
```

### 3. User Height/Count Section (Y: 195-370)

**Purpose**: User capacity and safety measurements

- Containing wall heights with comments
- Platform heights and measurements
- User capacity by height categories (1.0m, 1.2m, 1.5m, 1.8m)
- Play area dimensions and adjustments

### 4. Slide Section (Y: 372-520)

**Purpose**: Slide-specific safety assessments

- Platform and wall height measurements
- First metre and remaining wall heights
- Permanent roof status
- Run-out measurements and pass/fail assessments

### 5. Structure Section (Y: 525-770)

**Purpose**: Structural integrity assessments
**Left Column Content**:

- Seam integrity and lock stitching
- Stitch length measurements
- Air loss and wall alignment
- Sharp edges and stability checks
- Evacuation time assessments

### 6. Structure Continued Section (Right Column)

**Purpose**: Additional structural assessments
**Right Column Content** (X: 312.5):

- Step/ramp size validation
- Fall-off height measurements
- Unit pressure testing
- Trough dimension checks
- Entrapment and marking assessments

### 7. Anchorage Section (Right Column)

**Purpose**: Anchoring system evaluation

- Anchor count (high + low points)
- Anchor type and accessory compliance
- Angle and pull strength testing

### 8. Totally Enclosed Section (Right Column)

**Purpose**: Enclosed equipment specific checks

- Exit number and visibility requirements
- Emergency evacuation compliance

### 9. Materials Section (Right Column)

**Purpose**: Material quality and compliance

- Rope specifications and measurements
- Netting, zip, and window assessments
- Fabric strength and fire retardancy

### 10. Fan/Blower Section (Right Column)

**Purpose**: Electrical and blower system safety

- Blower size and capacity
- Return flap and finger probe tests
- PAT testing and visual inspection
- Serial number documentation

### 11. Risk Assessment Section (Y: 795-825)

**Purpose**: Comprehensive risk evaluation

```csharp
XRect rect2 = new XRect(15, 795, 564, 25);
gfx.DrawRectangle(XBrushes.LavenderBlush, rect2);
tf.DrawString("Risk Assessment: " + riskNotes, smallFont, XBrushes.Black, rect2, XStringFormats.TopLeft);
```

### 12. Testimony Section (Y: 812-825)

**Purpose**: Inspector certification statement

```csharp
XRect rect3 = new XRect(15, 812, 564, 9);
gfx.DrawRectangle(XBrushes.LavenderBlush, rect3);
tf.DrawString("Testimony: " + testimony.Text, smallFont, XBrushes.Black, rect3, XStringFormats.TopLeft);
```

### 13. Final Result Section (Y: 836)

**Purpose**: Pass/fail determination

- Dynamic color coding (Green/Red)
- Clear pass/fail statement

### 14. Footer Section (Y: 828)

**Purpose**: Software attribution

```csharp
XRect rect = new XRect(293, 828, 285, 10);
gfx.DrawRectangle(XBrushes.SeaShell, rect);
tf.DrawString("The software used to generate this report was made by Spencer Elliott.", regularFontBold, XBrushes.Black, rect, XStringFormats.TopLeft);
```

---

## Image Processing

### Image Compression

**Method**: `compressImage(Image image, double x, double y)`

- **Target Size**: 128×95 pixels maximum
- **Aspect Ratio**: Preserved during compression
- **Format**: PNG for PDF inclusion

### Image Positioning

```csharp
// Unit photo (top right)
if (unitPic.Image != null)
{
    Image img = compressImage(unitPic.Image, 128.0, 95.0);
    XImage xfoto = XImage.FromStream(pngStream);
    gfx.DrawImage(xfoto, 455, 15, img.Width, img.Height);
}

// Inspector logo (center right)
if (inspectorsLogo.Image != null)
{
    Image img = compressImage(inspectorsLogo.Image, 128.0, 95.0);
    XImage xfoto = XImage.FromStream(pngStream);
    gfx.DrawImage(xfoto, 315, 15, img.Width, img.Height);
}
```

---

## Text Formatting

### Text Truncation

**Method**: `truncateText(string text, int maxLength)`
**Usage**: Ensures content fits within page constraints
**Common Limits**:

- Comments: 60 characters
- Descriptions: 66 characters
- Location: 60 characters

### Text Positioning

**Vertical Spacing**: 8 points between lines
**Horizontal Positions**:

- Left column: X = 15
- Right column: X = 312.5
- Images: X = 315 (logo), X = 455 (photo)

---

## File Management

### Auto-Save Configuration

```csharp
string path = Path.Combine(
    Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments),
    "RPII Reports ",
    DateTime.Now.ToString("yyyy-MM-dd")
);

string filename = "RPII Report - " + " - " + uniquereportNum.Text +
                  DateTime.Now.ToString("yyyy-MM-dd HH-mm-ss") + ".pdf";
```

### Directory Structure

- **Base Path**: User's Documents folder
- **Subfolder**: "RPII Reports [DATE]"
- **Filename Format**: "RPII Report - - [REPORT_NUMBER][TIMESTAMP].pdf"

### Post-Generation Cleanup

```csharp
// Clear form fields after PDF creation
uniquereportNum.Text = "";
unitPic.Image = null;
```

---

## Coordinate Reference

### Key Y-Coordinates

| Section         | Start Y | Content                |
| --------------- | ------- | ---------------------- |
| Header          | 15-100  | Company info, dates    |
| Unit Details    | 130-190 | Equipment specs        |
| User Height     | 195-370 | Measurements, capacity |
| Slide           | 372-520 | Slide assessments      |
| Structure       | 525-770 | Safety checks          |
| Risk Assessment | 795-825 | Risk notes             |
| Result          | 836     | Pass/fail              |

### Key X-Coordinates

| Position       | X Value | Usage               |
| -------------- | ------- | ------------------- |
| Left Margin    | 15      | Main content column |
| Right Column   | 312.5   | Secondary content   |
| Logo Position  | 315     | Inspector logo      |
| Photo Position | 455     | Unit photo          |

---

## Error Handling

### PDF Generation Errors

```csharp
try
{
    // PDF generation logic
}
catch (Exception ex)
{
    MessageBox.Show(ex.Message, toolName);
}
```

### Validation Checks

1. **Report Number**: Must exist before PDF generation
2. **Image Processing**: Handles null images gracefully
3. **Text Content**: Validates and truncates as needed
4. **Directory Creation**: Creates output directory if missing

This comprehensive PDF generation system creates professional inspection reports that meet industry standards for safety documentation and regulatory compliance.
