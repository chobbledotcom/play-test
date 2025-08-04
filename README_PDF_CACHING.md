# PDF Caching Feature

This application now supports caching generated PDFs in S3/object storage to improve performance.

## How it works

1. When `PDF_CACHE_FROM` environment variable is set, the system will cache generated PDFs
2. The cached PDF is stored as an Active Storage attachment on the inspection/unit record
3. On subsequent requests, if the cached PDF is newer than the `PDF_CACHE_FROM` date, it will be served from cache
4. Cache is automatically invalidated when the record is updated

## Configuration

Set the `PDF_CACHE_FROM` environment variable to enable caching:

```bash
# Enable PDF caching for PDFs generated after January 1, 2024
export PDF_CACHE_FROM="2024-01-01"

# Disable PDF caching (default)
export PDF_CACHE_FROM=""
```

## Usage

The caching is transparent to the application. Controllers continue to work as before:

```ruby
# InspectionsController
def show
  respond_to do |format|
    format.pdf { send_inspection_pdf }
  end
end

private

def send_inspection_pdf
  # This now uses PdfCacheService internally
  pdf_data = PdfCacheService.fetch_or_generate_inspection_pdf(
    @inspection,
    debug_enabled: admin_debug_enabled?,
    debug_queries: debug_sql_queries
  )
  
  send_data pdf_data,
    filename: pdf_filename,
    type: "application/pdf",
    disposition: "inline"
end
```

## Cache Invalidation

The cache is automatically invalidated in these scenarios:

1. When an inspection is updated (any field change)
2. When a unit is updated (any field change)
3. When an inspection is completed (invalidates the unit's cached PDF)

## Storage

Cached PDFs are stored using Active Storage, which means:
- In development: stored in local filesystem
- In production with S3: stored in S3 bucket
- The storage location follows your Active Storage configuration

## Performance Benefits

- Reduces PDF generation time from seconds to milliseconds for cached PDFs
- Reduces server CPU usage
- Improves user experience with faster PDF loading

## When to Change PDF_CACHE_FROM

Update the `PDF_CACHE_FROM` date when you:
- Change PDF layout or design
- Update PDF content structure
- Fix bugs in PDF generation

This ensures all users get the updated PDF format.