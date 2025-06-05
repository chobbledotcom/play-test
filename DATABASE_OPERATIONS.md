# RPII Utility - Database Operations and SQL Documentation

## Overview

The RPII Utility uses SQLite as its database engine for storing inspection records. This document provides comprehensive documentation of all database operations, SQL statements, data handling patterns, and database management functionality.

## Database Configuration

### Database Engine
- **Technology**: SQLite 3
- **Package**: System.Data.SQLite v1.0.119
- **File Location**: Application execution directory
- **Database File**: `RPIIInspections.db`

### Connection Management

#### Connection String
```csharp
"Data Source=RPIIInspections.db; Version = 3; New = True; Compress = True;"
```

**Connection Parameters**:
- `Data Source`: Database filename (creates if doesn't exist)
- `Version`: SQLite version 3
- `New = True`: Creates database file if it doesn't exist
- `Compress = True`: Enables data compression

#### Connection Method
**Method**: `CreateConnection()`  
**Location**: Form1.cs:71  
**Purpose**: Create and open database connection  

```csharp
SQLiteConnection CreateConnection()
{
    SQLiteConnection sqlite_conn;
    sqlite_conn = new SQLiteConnection("Data Source=RPIIInspections.db; Version = 3; New = True; Compress = True;");
    
    try
    {
        sqlite_conn.Open();
    }
    catch (Exception ex)
    {
        // Silent error handling - connection issues not displayed to user
    }
    return sqlite_conn;
}
```

**Error Handling**: Silent catch - connection errors are not displayed to user

---

## Database Schema

### Table Structure

#### Primary Table: `Inspections`
**Creation Method**: `CreateTable(SQLiteConnection conn)`  
**Location**: Form1.cs:96  

```sql
CREATE TABLE IF NOT EXISTS Inspections (
    -- Primary Key & Global Details
    TagID INTEGER PRIMARY KEY,
    inspectionCompany TEXT,
    inspectionDate TEXT,
    RPIIRegNum TEXT,
    placeInspected TEXT,
    
    -- Unit Details (13 fields)
    unitDescription TEXT,
    unitManufacturer TEXT,
    unitWidth REAL,
    unitLength REAL,
    unitHeight REAL,
    serial TEXT,
    unitType TEXT,
    unitOwner TEXT,
    image TEXT,
    
    -- User Height/Count Measurements (22 fields)
    containingWallHeight REAL,
    containingWallHeightComment TEXT,
    platformHeight REAL,
    platformHeightComment TEXT,
    slideBarrierHeight REAL,
    slideBarrierHeightComment TEXT,
    remainingSlideWallHeight REAL,
    remainingSlideWallHeightComment TEXT,
    permanentRoof INTEGER,
    permanentRoofComment TEXT,
    userHeight REAL,
    userHeightComment TEXT,
    playAreaLength REAL,
    playAreaLengthComment TEXT,
    playAreaWidth REAL,
    playAreaWidthComment TEXT,
    negAdjustment REAL,
    negAdjustmentComment TEXT,
    usersat1000mm INTEGER,
    usersat1200mm INTEGER,
    usersat1500mm INTEGER,
    usersat1800mm INTEGER,
    
    -- Slide Measurements (14 fields)
    slidePlatformHeight REAL,
    slidePlatformHeightComment TEXT,
    slideWallHeight REAL,
    slideWallHeightComment TEXT,
    slideFirstMetreHeight REAL,
    slideFirstMetreHeightComment TEXT,
    slideBeyondFirstMetreHeight REAL,
    slideBeyondFirstMetreHeightComment TEXT,
    slidePermanentRoof INTEGER,
    slidePermanentRoofComment TEXT,
    clamberNettingPass INTEGER,
    clamberNettingComment TEXT,
    runoutValue REAL,
    runoutPass INTEGER,
    runoutComment TEXT,
    slipSheetPass INTEGER,
    slipSheetComment TEXT,
    
    -- Structure Assessments (34 fields)
    seamIntegrityPass INTEGER,
    seamIntegrityComment TEXT,
    lockStitchPass INTEGER,
    lockStitchComment TEXT,
    stitchLength INTEGER,
    stitchLengthPass INTEGER,
    stitchLengthComment TEXT,
    airLossPass INTEGER,
    airLossComment TEXT,
    straightWallsPass INTEGER,
    straightWallsComment TEXT,
    sharpEdgesPass INTEGER,
    sharpEdgesComment TEXT,
    blowerTubeLength REAL,
    blowerTubeLengthPass INTEGER,
    blowerTubeLengthComment TEXT,
    unitStablePass INTEGER,
    unitStableComment TEXT,
    evacTime INTEGER,
    evacTimePass INTEGER,
    evacTimeComment TEXT,
    stepSizeValue REAL,
    stepSizePass INTEGER,
    stepSizeComment TEXT,
    falloffHeightValue REAL,
    falloffHeightPass INTEGER,
    falloffHeightComment TEXT,
    unitPressureValue REAL,
    unitPressurePass INTEGER,
    unitPressureComment TEXT,
    troughDepthValue REAL,
    troughWidthValue REAL,
    troughPass INTEGER,
    troughComment TEXT,
    entrapPass INTEGER,
    entrapComment TEXT,
    markingsPass INTEGER,
    markingsComment TEXT,
    groundingPass INTEGER,
    groundingComment TEXT,
    
    -- Anchorage System (12 fields)
    numLowAnchors INTEGER,
    numHighAnchors INTEGER,
    numAnchorsPass INTEGER,
    numAnchorsComment TEXT,
    anchorAccessoriesPass INTEGER,
    anchorAccessoriesComment TEXT,
    anchorDegreePass INTEGER,
    anchorDegreeComment TEXT,
    anchorTypePass INTEGER,
    anchorTypeComment TEXT,
    pullStrengthPass INTEGER,
    pullStrengthComment TEXT,
    
    -- Totally Enclosed Equipment (6 fields)
    exitNumber INTEGER,
    exitNumberPass INTEGER,
    exitNumberComment TEXT,
    exitVisiblePass INTEGER,
    exitVisibleComment TEXT,
    
    -- Materials Assessment (20 fields)
    ropeSize INTEGER,
    ropeSizePass INTEGER,
    ropeSizeComment TEXT,
    clamberPass INTEGER,
    clamberComment TEXT,
    retentionNettingPass INTEGER,
    retentionNettingComment TEXT,
    zipsPass INTEGER,
    zipsComment TEXT,
    windowsPass INTEGER,
    windowsComment TEXT,
    artworkPass INTEGER,
    artworkComment TEXT,
    threadPass INTEGER,
    threadComment TEXT,
    fabricPass INTEGER,
    fabricComment TEXT,
    fireRetardentPass INTEGER,
    fireRetardentComment TEXT,
    
    -- Fan/Blower System (10 fields)
    fanSizeComment TEXT,
    blowerFlapPass INTEGER,
    blowerFlapComment TEXT,
    blowerFingerPass INTEGER,
    blowerFingerComment TEXT,
    patPass INTEGER,
    patComment TEXT,
    blowerVisualPass INTEGER,
    blowerVisualComment TEXT,
    blowerSerial TEXT,
    
    -- Risk Assessment & Final Result (4 fields)
    riskAssessment TEXT,
    passed INTEGER,
    Testimony TEXT
);
```

**Total Fields**: 142 fields across all inspection categories

---

## Data Operations

### Insert Operations

#### Primary Insert Method
**Method**: `InsertData(SQLiteConnection conn)`  
**Location**: Form1.cs:285  
**Purpose**: Insert complete inspection record  

#### Data Collection Process
1. **Form Field Extraction**: Convert all UI control values to strings
2. **Image Processing**: Compress and convert images to Base64 strings
3. **Boolean Conversion**: Convert checkbox states to string representations
4. **SQL Construction**: Build massive INSERT statement with 141 values

#### Image Data Handling
```csharp
// Compress and convert unit photo to Base64 string
string image = ConvertImageToString(compressImage(unitPic.Image, (double)400, (double)400));
```

**Image Storage Process**:
1. Compress image to 400×400 maximum dimensions
2. Convert to Base64 string representation
3. Store as TEXT field in database
4. Retrieve and convert back to Image object for display

#### INSERT Statement Structure
```sql
INSERT INTO Inspections(
    inspectionCompany,
    inspectionDate,
    RPIIRegNum,
    [... 138 more field names ...]
    Testimony
) VALUES (
    'company_name',
    'inspection_date',
    'rpii_number',
    [... 138 more values ...]
    'testimony_text'
);
```

#### Primary Key Retrieval
```csharp
// Get auto-generated primary key after insert
object obj = sqlite_cmd.ExecuteScalar();
long id = (long)obj;
uniquereportNum.Text = id.ToString();
```

**Process**:
1. Use `ExecuteScalar()` instead of `ExecuteNonQuery()` to get return value
2. Cast result to long for primary key ID
3. Set unique report number field with generated ID

### Select Operations

#### Load All Records
**SQL**: `SELECT * FROM Inspections;`  
**Trigger**: "Load All Historic Records" button  
**Method**: `loadRecords("SELECT * FROM Inspections;")`

#### Search by Owner
**SQL**: `SELECT * FROM Inspections WHERE unitOwner LIKE 'searchterm%';`  
**Trigger**: "Search by Owner" button with text input  
**Implementation**:
```csharp
if (searchbyUnitOwnerTxt.Text.Length > 0)
{
    loadRecords("SELECT * FROM Inspections WHERE unitOwner LIKE '" + searchbyUnitOwnerTxt.Text + "%';");
}
```

**Search Pattern**: Uses LIKE with trailing wildcard for partial matches

#### Search by Report Number
**SQL**: `SELECT * FROM Inspections WHERE TagID = report_number;`  
**Trigger**: "Search by Report Number" button with numeric input  
**Implementation**:
```csharp
if (uniqueReportNumberSearchTxt.Text.Length > 0)
{
    loadRecords("SELECT * FROM Inspections WHERE TagID = " + uniqueReportNumberSearchTxt.Text + ";");
}
```

**Search Pattern**: Exact match on primary key field

#### Record Loading Process
**Method**: `loadRecords(string query)`  
**Location**: Form1.cs:929  

```csharp
void loadRecords(string query)
{
    clearRecords();
    
    try
    {
        SQLiteConnection sqlite_conn = CreateConnection();
        SQLiteDataReader sqlite_datareader;
        SQLiteCommand sqlite_cmd = sqlite_conn.CreateCommand();
        sqlite_cmd.CommandText = query;
        
        sqlite_datareader = sqlite_cmd.ExecuteReader();
        
        while (sqlite_datareader.Read())
        {
            records.Rows.Add(
                sqlite_datareader.GetInt32(0).ToString(),    // TagID (Primary Key)
                sqlite_datareader.GetString(1),              // Inspection Company
                sqlite_datareader.GetString(2),              // Inspection Date
                [... 139 more field retrievals ...]
                ConvertStringToImage(sqlite_datareader.GetString(13)) // Unit Image
            );
        }
    }
    catch (Exception ex)
    {
        MessageBox.Show(ex.ToString(), toolName);
    }
}
```

---

## Data Type Handling

### Type Conversion Mapping

| UI Control Type | Database Type | Retrieval Method | Storage Format |
|-----------------|---------------|------------------|----------------|
| TextBox | TEXT | GetString() | Direct string |
| NumericUpDown (Integer) | INTEGER | GetInt32() | Integer value |
| NumericUpDown (Decimal) | REAL | GetDecimal() | Decimal value |
| CheckBox | INTEGER | GetString() → Parse | "True"/"False" string |
| RadioButton | INTEGER | GetString() → Parse | "True"/"False" string |
| DateTimePicker | TEXT | GetString() | ToLongDateString() |
| Image | TEXT | GetString() → Convert | Base64 encoded string |

### Data Conversion Methods

#### Boolean to String Conversion
```csharp
// Storage: Convert boolean to string
string passValue = checkboxControl.Checked.ToString(); // "True" or "False"

// Retrieval: Parse string back to boolean
bool passState = (bool)records.Rows[rowIndex].Cells[cellIndex].FormattedValue;
```

#### Image Data Conversion
```csharp
// Storage: Image → Base64 string
string ConvertImageToString(Image image)
{
    if (image != null)
    {
        byte[] byteArray;
        using (MemoryStream stream = new MemoryStream())
        {
            image.Save(stream, System.Drawing.Imaging.ImageFormat.Png);
            byteArray = stream.ToArray();
        }
        return Convert.ToBase64String(byteArray);
    }
    return null;
}

// Retrieval: Base64 string → Image
Image ConvertStringToImage(string ImgAsString)
{
    if (ImgAsString.Length > 0)
    {
        byte[] imageBytes = Convert.FromBase64String(ImgAsString);
        using (MemoryStream stream = new MemoryStream(imageBytes))
        {
            return Image.FromStream(stream);
        }
    }
    return null;
}
```

#### Numeric Data Handling
```csharp
// Storage: Numeric controls to string
string width = unitWidthNum.Value.ToString();

// Retrieval: String to specific numeric type
decimal widthValue = sqlite_datareader.GetDecimal(7);
int userCount = sqlite_datareader.GetInt32(32);
```

---

## Record Management

### Form Population
**Method**: `loadReportIntoApplication(int rowIndex)`  
**Location**: Form1.cs:1405  
**Purpose**: Load selected database record into form controls

#### Population Process
1. **Data Extraction**: Extract all field values from DataGridView row
2. **Type Conversion**: Convert database values to appropriate control types
3. **Form Assignment**: Populate all form controls with loaded data
4. **Image Restoration**: Convert Base64 strings back to images

#### Sample Population Code
```csharp
void loadReportIntoApplication(int rowIndex)
{
    try
    {
        // Global Details
        InspectionCompName.Text = records.Rows[rowIndex].Cells[1].Value.ToString();
        datePicker.Value = DateTime.Parse(records.Rows[rowIndex].Cells[2].Value.ToString());
        
        // Numeric Values
        unitWidthNum.Value = (decimal)records.Rows[rowIndex].Cells[7].Value;
        usersat1000mm.Value = (int)records.Rows[rowIndex].Cells[32].Value;
        
        // Boolean Values (using FormattedValue for safe casting)
        permanentRoofChecked.Checked = (bool)records.Rows[rowIndex].Cells[22].FormattedValue;
        
        // Images
        unitPic.Image = (Image)records.Rows[rowIndex].Cells[13].FormattedValue;
        
        // Final Result
        passedRadio.Checked = (bool)records.Rows[rowIndex].Cells[140].FormattedValue;
    }
    catch (Exception ex)
    {
        MessageBox.Show(ex.ToString(), toolName);
    }
}
```

### Clear Operations
**Method**: `clearRecords()`  
**Location**: Form1.cs:1394  
```csharp
void clearRecords()
{
    records.Rows.Clear();
}
```

---

## Security Considerations

### SQL Injection Vulnerability

**⚠️ CRITICAL SECURITY ISSUE**: The application is vulnerable to SQL injection attacks

#### Vulnerable Code Examples
```csharp
// Owner search - VULNERABLE to SQL injection
loadRecords("SELECT * FROM Inspections WHERE unitOwner LIKE '" + searchbyUnitOwnerTxt.Text + "%';");

// Report number search - VULNERABLE to SQL injection  
loadRecords("SELECT * FROM Inspections WHERE TagID = " + uniqueReportNumberSearchTxt.Text + ";");

// Insert operation - VULNERABLE to SQL injection
sqlite_cmd.CommandText = "INSERT INTO Inspections(...) VALUES ('" + userInput + "', ...)";
```

#### Security Recommendations
1. **Use Parameterized Queries**: Replace string concatenation with parameter binding
2. **Input Validation**: Validate and sanitize all user inputs
3. **Prepared Statements**: Use SQLiteParameter objects for safe SQL execution

#### Secure Implementation Example
```csharp
// SECURE: Parameterized query example
sqlite_cmd.CommandText = "SELECT * FROM Inspections WHERE unitOwner LIKE @owner";
sqlite_cmd.Parameters.AddWithValue("@owner", searchbyUnitOwnerTxt.Text + "%");
```

---

## Error Handling

### Database Connection Errors
```csharp
try
{
    sqlite_conn.Open();
}
catch (Exception ex)
{
    // Silent failure - errors not displayed to user
    // RECOMMENDATION: Add proper error logging and user notification
}
```

### SQL Execution Errors
```csharp
try
{
    sqlite_cmd.ExecuteNonQuery();
}
catch (Exception ex)
{
    MessageBox.Show(ex.ToString(), toolName); // Full exception details shown to user
}
```

### Data Loading Errors
```csharp
try
{
    // Data loading operations
}
catch (Exception ex)
{
    MessageBox.Show(ex.ToString(), toolName); // Exception details displayed
}
```

---

## Performance Considerations

### Database File Size
- **Image Storage**: Base64 encoding increases size by ~33%
- **Text Storage**: All data stored as TEXT/REAL fields
- **No Indexing**: Single table with no additional indexes

### Query Performance
- **Full Table Scans**: All searches perform full table scans
- **No Indexes**: No indexes on commonly searched fields (unitOwner, TagID)
- **Large Record Size**: Each record contains 142 fields

### Optimization Recommendations
1. **Add Indexes**: Create indexes on frequently searched columns
2. **Separate Image Storage**: Store images as separate files, reference by path
3. **Normalize Schema**: Consider breaking into related tables
4. **Query Optimization**: Use specific field selection instead of SELECT *

---

## Backup and Recovery

### File-Based Backup
- **Database File**: Copy `RPIIInspections.db` for complete backup
- **Location**: Application execution directory
- **No Built-in Backup**: Application doesn't provide automated backup functionality

### Data Export Recommendations
1. **Regular Backups**: Implement automated database file copying
2. **Export Functionality**: Add CSV/Excel export capabilities
3. **Cloud Sync**: Consider cloud backup for database file

---

## Database Maintenance

### File Management
- **Auto-Creation**: Database and table created automatically on first run
- **No Cleanup**: No automatic cleanup of old records
- **No Compaction**: No database maintenance routines

### Maintenance Recommendations
1. **Periodic Vacuum**: Run VACUUM command to reclaim space
2. **Data Archiving**: Implement archiving for old inspection records
3. **Integrity Checks**: Add periodic database integrity validation

This comprehensive database documentation provides complete understanding of the SQLite implementation, data flow, security considerations, and opportunities for improvement in the RPII Utility application.