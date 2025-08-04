# PDF Caching Feature

This application now supports caching generated PDFs in S3/object storage to improve performance.

## How it works

1. When `PDF_CACHE_FROM` environment variable is set, the system will cache generated PDFs
2. Only **completed inspections** are cached - in-progress inspections are always generated fresh
3. The cached PDF is stored as an Active Storage attachment on the inspection/unit record
4. On subsequent requests, if the cached PDF is newer than the `PDF_CACHE_FROM` date, the system:
   - Returns an HTTP 302 redirect to a signed Active Storage URL (valid for 1 hour)
   - This allows CDN caching and direct serving from S3/storage
5. Cache is automatically invalidated when the record is updated

## Configuration

Set the `PDF_CACHE_FROM` environment variable to enable caching:

```bash
# Enable PDF caching for PDFs generated after January 1, 2024
export PDF_CACHE_FROM="2024-01-01"

# Disable PDF caching (default)
export PDF_CACHE_FROM=""
```

**Note**: The date must be in `YYYY-MM-DD` format. Invalid formats will raise an `ArgumentError` to ensure configuration issues are caught early.

## Usage

The caching is transparent to the application. Controllers handle the caching response automatically:

```ruby
# InspectionsController
def show
  respond_to do |format|
    format.pdf { send_inspection_pdf }
  end
end

private

def send_inspection_pdf
  # PdfCacheService returns a CacheResult with type and data
  result = PdfCacheService.fetch_or_generate_inspection_pdf(
    @inspection,
    debug_enabled: admin_debug_enabled?,
    debug_queries: debug_sql_queries
  )
  
  case result.type
  when :redirect
    # Cache hit - redirect to signed URL
    redirect_to result.data, allow_other_host: true
  when :pdf_data
    # Cache miss - send generated PDF directly
    send_data result.data,
      filename: pdf_filename,
      type: "application/pdf",
      disposition: "inline"
  end
end
```

## Cache Invalidation

The cache is automatically invalidated in these scenarios:

1. When an inspection is updated (except for `pdf_last_accessed_at` or `updated_at` only changes)
2. When a unit is updated (except for `updated_at` only changes)
3. When an inspection is completed (invalidates the unit's cached PDF)

**Note**: The system intelligently skips cache invalidation when only timestamp fields are updated, preventing unnecessary cache purges when PDFs are accessed.

## Storage

Cached PDFs are stored using Active Storage, which means:
- In development: stored in local filesystem
- In production with S3: stored in S3 bucket
- The storage location follows your Active Storage configuration

## Performance Benefits

- Reduces PDF generation time from seconds to milliseconds for cached PDFs
- Reduces server CPU usage
- Improves user experience with faster PDF loading
- Enables CDN caching of PDF URLs (when using redirects)
- Offloads PDF serving to S3/storage service directly

## When to Change PDF_CACHE_FROM

Update the `PDF_CACHE_FROM` date when you:
- Change PDF layout or design
- Update PDF content structure
- Fix bugs in PDF generation

This ensures all users get the updated PDF format.