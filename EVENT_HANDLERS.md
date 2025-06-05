# RPII Utility - Event Handlers Documentation

## Overview

This document provides comprehensive documentation of all event handlers in the RPII Utility application, their functionality, and the data synchronization logic implemented to maintain consistency across the multi-tab interface.

## Button Click Event Handlers

### File Management Events

#### `uploadPhotoBtn_Click`
**Location**: Form1.cs:27  
**Purpose**: Upload equipment photo  
**Functionality**:
- Opens file dialog for image selection
- Validates image file format
- Displays selected image in `unitPic` PictureBox
- Handles exceptions with user notification

**Implementation**:
```csharp
private void uploadPhotoBtn_Click(object sender, EventArgs e)
{
    choosePhoto();
}
```

#### `selectLogoBtn_Click`
**Location**: Form1.cs:1650  
**Purpose**: Upload inspector logo  
**Functionality**:
- Opens file dialog for logo selection
- Validates image file format
- Displays selected logo in `inspectorsLogo` PictureBox
- Handles exceptions with user notification

**Implementation**:
```csharp
private void selectLogoBtn_Click(object sender, EventArgs e)
{
    chooseLogo();
}
```

### Database Management Events

#### `saveBtn_Click`
**Location**: Form1.cs:764  
**Purpose**: Save inspection data to database  
**Functionality**:
- Validates required fields
- Collects all form data
- Executes SQL INSERT statement
- Provides user feedback on save status

#### `newBtn_Click`
**Location**: Form1.cs:769  
**Purpose**: Clear form for new inspection  
**Functionality**:
- Resets all form controls to default values
- Clears images and selections
- Prepares form for new inspection entry

#### `createPDFBtn_Click`
**Location**: Form1.cs:774  
**Purpose**: Generate PDF inspection report  
**Functionality**:
- Calls `createPDFCert()` method
- Generates formatted PDF with all inspection data
- Includes images, measurements, and assessments
- Saves PDF to user-specified location

### Search and Data Retrieval Events

#### `loadAllRecordsBtn_Click`
**Location**: Form1.cs:1600  
**Purpose**: Load all inspection records  
**Functionality**:
- Queries database for all inspections
- Populates DataGridView with results
- Enables record selection and loading

#### `clrRecordsBtn_Click`
**Location**: Form1.cs:1605  
**Purpose**: Clear displayed records  
**Functionality**:
- Clears DataGridView content
- Resets search state
- Prepares for new search operations

#### `searchByOwnerBtn_Click`
**Location**: Form1.cs:1610  
**Purpose**: Search inspections by unit owner  
**Functionality**:
- Executes parameterized SQL query
- Filters results by owner name
- Displays matching records in DataGridView

#### `uniqueReportNumberSearchBtn_Click`
**Location**: Form1.cs:1622  
**Purpose**: Search by unique report number  
**Functionality**:
- Searches for specific inspection by ID
- Loads exact match if found
- Provides targeted record retrieval

## Value Changed Event Handlers

### Cross-Tab Data Synchronization

The application implements bi-directional synchronization between related measurements across different tabs to ensure data consistency and reduce data entry duplication.

#### Platform Height Synchronization

##### `platformHeightValue_ValueChanged`
**Location**: Form1.cs:781  
**Purpose**: Sync User Height tab → Slide tab  
**Functionality**:
- Updates `slidePlatformHeightValue` when `platformHeightValue` changes
- Maintains consistency between User Height and Slide tabs

**Implementation**:
```csharp
private void platformHeightValue_ValueChanged(object sender, EventArgs e)
{
    slidePlatformHeightValue.Value = platformHeightValue.Value;
}
```

##### `slidePlatformHeightValue_ValueChanged`
**Location**: Form1.cs:788  
**Purpose**: Sync Slide tab → User Height tab  
**Functionality**:
- Updates `platformHeightValue` when `slidePlatformHeightValue` changes
- Reverse synchronization for bi-directional consistency

#### Wall Height Synchronization

##### `slideWallHeightValue_ValueChanged`
**Location**: Form1.cs:795  
**Purpose**: Sync Slide wall height → Containing wall height  
**Functionality**:
- Updates `containingWallHeightValue` when `slideWallHeightValue` changes
- Ensures slide and general wall heights remain consistent

##### `containingWallHeightValue_ValueChanged`
**Location**: Form1.cs:802  
**Purpose**: Sync Containing wall height → Slide wall height  
**Functionality**:
- Updates `slideWallHeightValue` when `containingWallHeightValue` changes
- Bi-directional synchronization for wall measurements

#### First Metre Height Synchronization

##### `slidefirstmetreHeightValue_ValueChanged`
**Location**: Form1.cs:809  
**Purpose**: Sync Slide first metre → Barrier height  
**Functionality**:
- Updates `slidebarrierHeightValue` when `slidefirstmetreHeightValue` changes
- Maintains consistency between slide measurement tabs

##### `slidebarrierHeightValue_ValueChanged`
**Location**: Form1.cs:816  
**Purpose**: Sync Barrier height → Slide first metre  
**Functionality**:
- Updates `slidefirstmetreHeightValue` when `slidebarrierHeightValue` changes
- Reverse synchronization for first metre measurements

#### Remaining Height Synchronization

##### `remainingSlideWallHeightValue_ValueChanged`
**Location**: Form1.cs:823  
**Purpose**: Sync Remaining wall height → Beyond first metre  
**Functionality**:
- Updates `beyondfirstmetreHeightValue` when `remainingSlideWallHeightValue` changes
- Ensures slide segment measurements are consistent

##### `beyondfirstmetreHeightValue_ValueChanged`
**Location**: Form1.cs:830  
**Purpose**: Sync Beyond first metre → Remaining wall height  
**Functionality**:
- Updates `remainingSlideWallHeightValue` when `beyondfirstmetreHeightValue` changes
- Bi-directional sync for slide end measurements

## CheckBox Event Handlers

### Permanent Roof Synchronization

#### `slidePermRoofedCheck_CheckedChanged`
**Location**: Form1.cs:837  
**Purpose**: Sync Slide permanent roof → User Height permanent roof  
**Functionality**:
- Updates `permanentRoofChecked` when `slidePermRoofedCheck` changes
- Ensures roof status consistency across tabs

**Implementation**:
```csharp
private void slidePermRoofedCheck_CheckedChanged(object sender, EventArgs e)
{
    permanentRoofChecked.Checked = slidePermRoofedCheck.Checked;
}
```

#### `permanentRoofChecked_CheckedChanged`
**Location**: Form1.cs:844  
**Purpose**: Sync User Height permanent roof → Slide permanent roof  
**Functionality**:
- Updates `slidePermRoofedCheck` when `permanentRoofChecked` changes
- Bi-directional roof status synchronization

## Event Handler Design Patterns

### Synchronization Pattern
All cross-tab synchronization events follow this pattern:
1. **Trigger**: User changes value in one tab
2. **Handler**: Automatically updates corresponding field in related tab
3. **Consistency**: Maintains data integrity across the application
4. **Bi-directional**: Changes propagate in both directions

### Error Handling Pattern
Button click events implement consistent error handling:
1. **Try-Catch**: Wrap operations in exception handling
2. **User Feedback**: Display meaningful error messages
3. **Application Stability**: Prevent crashes from invalid operations
4. **Logging**: Record errors for debugging (via comments)

### Validation Pattern
Data entry events implement validation:
1. **Type Safety**: Numeric controls enforce proper data types
2. **Range Checking**: Prevent unrealistic values
3. **Required Fields**: Ensure critical data is present
4. **Format Validation**: Maintain consistent data formats

## Event Subscription Management

### Designer-Generated Subscriptions
Event subscriptions are managed in `Form1.Designer.cs`:

```csharp
// Click Events
selectLogoBtn.Click += selectLogoBtn_Click;
uploadPhotoBtn.Click += uploadPhotoBtn_Click;
saveBtn.Click += saveBtn_Click;
createPDFBtn.Click += createPDFBtn_Click;

// Value Changed Events
platformHeightValue.ValueChanged += platformHeightValue_ValueChanged;
slidePlatformHeightValue.ValueChanged += slidePlatformHeightValue_ValueChanged;

// CheckBox Events
permanentRoofChecked.CheckedChanged += permanentRoofChecked_CheckedChanged;
slidePermRoofedCheck.CheckedChanged += slidePermRoofedCheck_CheckedChanged;
```

### Event Handler Benefits

1. **Data Consistency**: Automatic synchronization prevents data discrepancies
2. **User Experience**: Reduces duplicate data entry
3. **Validation**: Real-time validation and feedback
4. **Error Prevention**: Handles edge cases and invalid operations
5. **Workflow Efficiency**: Streamlines inspection process

## Data Flow Architecture

### Synchronization Chain Examples

#### Platform Height Data Flow:
```
User Height Tab: platformHeightValue
    ↕ (bi-directional sync)
Slide Tab: slidePlatformHeightValue
```

#### Wall Height Data Flow:
```
User Height Tab: containingWallHeightValue
    ↕ (bi-directional sync)
Slide Tab: slideWallHeightValue
```

#### Permanent Roof Data Flow:
```
User Height Tab: permanentRoofChecked
    ↕ (bi-directional sync)
Slide Tab: slidePermRoofedCheck
```

This event handler architecture ensures that related measurements remain consistent across the multi-tab interface while providing a smooth user experience and maintaining data integrity throughout the inspection process.