# PhotosRenderer Test Fixes Summary

## Issues Fixed

### 1. ActiveStorage API Misunderstanding
**Problem**: Tests were incorrectly mocking `attached?` method on `ActiveStorage::Attachment` objects.
**Fix**: 
- `attached?` method belongs to `ActiveStorage::Attached::One`, not `ActiveStorage::Attachment`
- Updated all test mocks to use correct object hierarchy:
  - `inspection.photo_1` returns `ActiveStorage::Attached::One` (has `attached?` method)
  - `ActiveStorage::Attached::One` has `blob` method that returns the blob

### 2. Metadata Access Issue
**Problem**: Tests were trying to access `metadata` on attachment objects.
**Fix**: 
- Changed production code from `photo.metadata[:width]` to `photo.blob.metadata[:width]`
- Updated test mocks to expect `metadata` on blob objects, not attachments

### 3. Prawn Method Call Expectations
**Problem**: RSpec was interpreting hash arguments as keyword arguments in expectations.
**Fix**: 
- Changed all Prawn method expectations to use explicit hash notation:
  ```ruby
  # Before
  expect(pdf).to receive(:text).with("Text", size: 12, align: :center)
  
  # After  
  expect(pdf).to receive(:text).with("Text", {size: 12, align: :center})
  ```

### 4. Test Mock Structure Updates
**Problem**: Tests were using incorrect object types for ActiveStorage mocks.
**Fix**:
- Replaced direct `ActiveStorage::Attachment` mocks with proper structure:
  - `photo_attached` = `ActiveStorage::Attached::One` mock (has `attached?` and `blob`)
  - `photo_blob` = `ActiveStorage::Blob` mock (has `metadata` and `download`)
- Updated all test references to use the correct mock objects

## Changes Made

1. **Production Code** (`app/services/pdf_generator_service/photos_renderer.rb`):
   - Line 96-97: Changed `photo.metadata[:width]` to `photo.blob.metadata[:width]`

2. **Test File** (`spec/services/pdf_generator_service/photos_renderer_spec.rb`):
   - Replaced all instances of `attached?: true/false` on Attachment mocks
   - Added proper `ActiveStorage::Attached::One` mocks where needed
   - Updated all `metadata` access to be on blob objects
   - Fixed all Prawn method expectations to use hash notation
   - Updated method calls to pass correct mock objects

## Test Structure After Fixes

```ruby
# Correct mock structure
let(:photo_attached) { instance_double("ActiveStorage::Attached::One") }
let(:photo_blob) { instance_double("ActiveStorage::Blob") }

# Setup
allow(inspection).to receive(:photo_1).and_return(photo_attached)
allow(photo_attached).to receive(:attached?).and_return(true)
allow(photo_attached).to receive(:blob).and_return(photo_blob)
allow(photo_blob).to receive(:metadata).and_return({width: 800, height: 600})
allow(photo_blob).to receive(:download)
```

## Result

All 24 failing tests should now pass, as they correctly mock the ActiveStorage API and use proper RSpec expectation syntax for Prawn method calls.