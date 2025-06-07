# RPII Utility - API/Method Reference Documentation

## Overview

This document provides comprehensive reference documentation for all methods and functions in the RPII Utility application. Methods are organized by functionality and include complete signatures, parameters, return values, and usage examples.

## Core Application Methods

### Application Entry Point

#### `Main()`

**Location**: Program.cs:9
**Signature**: `static void Main()`
**Purpose**: Application entry point
**Functionality**:

- Initializes Windows Forms application configuration
- Creates and runs main Form1 instance
- Sets up application-wide settings

---

## Database Operations

### Connection Management

#### `CreateConnection()`

**Location**: Form1.cs:71
**Signature**: `SQLiteConnection CreateConnection()`
**Purpose**: Create and open SQLite database connection
**Returns**: `SQLiteConnection` - Active database connection
**Functionality**:

- Creates SQLite database file if it doesn't exist
- Opens connection to `RPIIInspections.db`
- Uses connection string: `"Data Source=RPIIInspections.db; Version = 3; New = True; Compress = True;"`
- Handles connection exceptions silently

**Usage Example**:

```csharp
SQLiteConnection conn = CreateConnection();
// Use connection for database operations
```

### Table Management

#### `CreateTable(SQLiteConnection conn)`

**Location**: Form1.cs:96
**Signature**: `void CreateTable(SQLiteConnection conn)`
**Purpose**: Create inspection table if it doesn't exist
**Parameters**:

- `conn` - Active SQLite database connection
  **Functionality**:
- Creates `Inspections` table with complete schema
- Includes all 142 inspection fields
- Uses `CREATE TABLE IF NOT EXISTS` for safety
- Handles table creation exceptions with user notification

### Data Operations

#### `InsertData(SQLiteConnection conn)`

**Location**: Form1.cs:285
**Signature**: `void InsertData(SQLiteConnection conn)`
**Purpose**: Insert current inspection data into database
**Parameters**:

- `conn` - Active SQLite database connection
  **Functionality**:
- Collects all form field values
- Constructs parameterized INSERT statement
- Handles image data conversion
- Executes database insertion with error handling

#### `saveInspection()`

**Location**: Form1.cs:736
**Signature**: `void saveInspection()`
**Purpose**: Complete save workflow for current inspection
**Functionality**:

- Creates database connection
- Creates table if needed
- Inserts current inspection data
- Provides user feedback on save status

### Record Retrieval

#### `loadRecords(string query)`

**Location**: Form1.cs:929
**Signature**: `void loadRecords(string query)`
**Purpose**: Load inspection records into DataGridView
**Parameters**:

- `query` - SQL SELECT statement to execute
  **Functionality**:
- Clears existing records display
- Executes provided SQL query
- Populates DataGridView with results
- Handles database read exceptions

**Usage Examples**:

```csharp
// Load all records
loadRecords("SELECT * FROM Inspections;");

// Load filtered records
loadRecords("SELECT * FROM Inspections WHERE unitOwner LIKE '%Smith%';");
```

#### `loadReportIntoApplication(int rowIndex)`

**Location**: Form1.cs:1405
**Signature**: `void loadReportIntoApplication(int rowIndex)`
**Purpose**: Load selected inspection record into form fields
**Parameters**:

- `rowIndex` - Index of record in DataGridView to load
  **Functionality**:
- Extracts all field values from selected DataGridView row
- Populates all form controls with loaded data
- Handles type conversions for different field types
- Restores images and checkbox states

#### `clearRecords()`

**Location**: Form1.cs:1394
**Signature**: `void clearRecords()`
**Purpose**: Clear all records from DataGridView
**Functionality**:

- Removes all rows from records DataGridView
- Resets display for new search operations

---

## Image Processing

### Image Conversion

#### `ConvertStringToImage(string ImgAsString)`

**Location**: Form1.cs:851
**Signature**: `Image ConvertStringToImage(string ImgAsString)`
**Purpose**: Convert Base64 string to Image object
**Parameters**:

- `ImgAsString` - Base64 encoded image string
  **Returns**: `Image` - Decoded image object, or `null` if empty string
  **Functionality**:
- Validates input string length
- Converts Base64 string to byte array
- Creates Image from memory stream
- Handles conversion errors gracefully

#### `ConvertImageToString(Image image)`

**Location**: Form1.cs:897
**Signature**: `string ConvertImageToString(Image image)`
**Purpose**: Convert Image object to Base64 string
**Parameters**:

- `image` - Image object to convert
  **Returns**: `string` - Base64 encoded image data, or `null` if image is null
  **Functionality**:
- Validates input image is not null
- Saves image to memory stream as PNG
- Converts byte array to Base64 string
- Ensures proper resource disposal

#### `compressImage(Image image, double x, double y)`

**Location**: Form1.cs:873
**Signature**: `Image compressImage(Image image, double x, double y)`
**Purpose**: Resize image while maintaining aspect ratio
**Parameters**:

- `image` - Source image to compress
- `x` - Target width constraint
- `y` - Target height constraint
  **Returns**: `Image` - Compressed image, or `null` if source is null
  **Functionality**:
- Calculates optimal resize ratio maintaining aspect ratio
- Creates new bitmap with calculated dimensions
- Draws resized image using Graphics object
- Prevents distortion by using minimum ratio

**Usage Example**:

```csharp
// Compress image to fit within 128x95 pixels
Image compressed = compressImage(originalImage, 128.0, 95.0);
```

### File Operations

#### `choosePhoto()`

**Location**: Form1.cs:37
**Signature**: `void choosePhoto()`
**Purpose**: Handle equipment photo selection and display
**Functionality**:

- Opens file dialog for image selection
- Validates selected file can be loaded as bitmap
- Displays image in `unitPic` PictureBox
- Shows error message if file loading fails

#### `chooseLogo()`

**Location**: Form1.cs:53
**Signature**: `void chooseLogo()`
**Purpose**: Handle inspector logo selection and display
**Functionality**:

- Opens file dialog for logo selection
- Validates selected file can be loaded as bitmap
- Displays logo in `inspectorsLogo` PictureBox
- Shows error message if file loading fails

---

## PDF Generation

### Report Creation

#### `createPDFCert()`

**Location**: Form1.cs:1122
**Signature**: `void createPDFCert()`
**Purpose**: Generate complete PDF inspection report
**Functionality**:

- Validates unique report number is present
- Creates PDF document with complete inspection data
- Includes all measurements, assessments, and images
- Formats data across multiple sections
- Handles image compression for PDF inclusion
- Saves PDF to user-specified location
- Provides comprehensive inspection report

**PDF Content Sections**:

1. Header with logos and inspection details
2. Unit specifications and photo
3. Height measurements and user capacity
4. Slide measurements and safety checks
5. Structural integrity assessments
6. Anchorage system evaluation
7. Materials compliance checks
8. Fan/blower system inspection
9. Risk assessment notes
10. Final pass/fail determination

---

## Utility Methods

### Text Processing

#### `truncateText(string text, int maxLength)`

**Location**: Form1.cs:1105
**Signature**: `string truncateText(string text, int maxLength)`
**Purpose**: Truncate text to specified maximum length
**Parameters**:

- `text` - Original text string
- `maxLength` - Maximum allowed character length
  **Returns**: `string` - Truncated text (original if within limit)
  **Functionality**:
- Validates text length against maximum
- Returns substring if text exceeds limit
- Preserves original text if within limit
- Used extensively in PDF generation for comment fields

**Usage Example**:

```csharp
// Truncate comment to 60 characters for PDF display
string shortComment = truncateText(fullComment, 60);
```

---

## Form Management

### Form State

#### `Form1()` (Constructor)

**Location**: Form1.cs:19
**Signature**: `public Form1()`
**Purpose**: Initialize main form and default values
**Functionality**:

- Calls `InitializeComponent()` for UI setup
- Sets inspection date to current date
- Initializes form state for new inspection

### Form Reset

#### `newBtn_Click()` Implementation

**Purpose**: Reset form for new inspection entry
**Functionality**:

- Clears all text fields
- Resets numeric controls to defaults
- Unchecks all checkboxes
- Clears radio button selections
- Removes loaded images
- Prepares form for fresh inspection data

---

## Search Operations

### Search Methods

#### Owner Search Implementation

**Purpose**: Search inspections by equipment owner
**Functionality**:

- Constructs SQL query with LIKE operator
- Searches `unitOwner` field for partial matches
- Calls `loadRecords()` with filtered query

#### Report Number Search Implementation

**Purpose**: Search by unique report identifier
**Functionality**:

- Constructs exact match SQL query
- Searches `TagID` field for specific record
- Loads single matching inspection

---

## Error Handling Patterns

### Database Error Handling

```csharp
try
{
    // Database operation
}
catch (Exception ex)
{
    MessageBox.Show(ex.ToString(), toolName);
}
```

### Image Processing Error Handling

```csharp
try
{
    // Image operation
}
catch (Exception ex)
{
    MessageBox.Show(ex.Message, toolName);
}
```

### File Operation Error Handling

- File dialog validation
- Image format validation
- Path existence checking
- User-friendly error messages

---

## Method Dependencies

### Database Operation Flow

1. `CreateConnection()` → Database connection
2. `CreateTable()` → Table initialization
3. `InsertData()` → Data persistence
4. `loadRecords()` → Data retrieval

### Image Processing Flow

1. File selection → `choosePhoto()` / `chooseLogo()`
2. Display → PictureBox assignment
3. Compression → `compressImage()`
4. Storage → `ConvertImageToString()`
5. Retrieval → `ConvertStringToImage()`

### PDF Generation Flow

1. Validation → Check required fields
2. Image processing → `compressImage()`
3. Content creation → `createPDFCert()`
4. Text formatting → `truncateText()`
5. File output → User save dialog

This API reference provides complete documentation for all public and private methods in the RPII Utility application, enabling developers to understand, maintain, and extend the codebase effectively.
