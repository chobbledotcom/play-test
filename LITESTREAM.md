# Litestream Integration

This application supports [Litestream](https://litestream.io/) for continuous replication of SQLite databases to S3-compatible object storage.

## Overview

When Litestream is enabled:
- The application automatically restores databases from S3 on startup if they don't exist locally
- Continuous replication runs in the background, streaming WAL updates to S3
- The Docker image becomes truly stateless - all data is stored in S3

## Configuration

### Environment Variables

Add these to your `.env` file or environment:

```bash
# Enable Litestream
LITESTREAM_ENABLED=true

# S3 Configuration
LITESTREAM_S3_BUCKET=your-litestream-bucket
LITESTREAM_S3_ENDPOINT=https://s3.amazonaws.com
LITESTREAM_S3_REGION=us-east-1
LITESTREAM_ACCESS_KEY_ID=your-access-key
LITESTREAM_SECRET_ACCESS_KEY=your-secret-key
```

### S3 Bucket Setup

1. Create an S3 bucket (or use an S3-compatible service like Backblaze B2, DigitalOcean Spaces, etc.)
2. Create an IAM user/access key with permissions to read/write to the bucket
3. Set the environment variables as shown above

### Litestream Configuration

The Litestream configuration is in `config/litestream.yml`. It replicates two databases:
- `storage/production.sqlite3` - Main application database
- `storage/production_queue.sqlite3` - Solid Queue background jobs database

Key settings:
- **Sync interval**: 10 seconds (how often WAL changes are pushed to S3)
- **Retention**: 7 days (how long to keep historical snapshots)
- **Snapshot interval**: 24 hours (how often to create full snapshots)

## How It Works

### On Container Startup

1. The Docker entrypoint checks if `LITESTREAM_ENABLED=true`
2. For each database file:
   - If it doesn't exist locally, attempts to restore from S3
   - If no backup exists in S3, continues normally (new database will be created)
3. Starts the Litestream replication process in the background
4. Starts the Rails server

### During Operation

- Litestream monitors the SQLite WAL (Write-Ahead Log) files
- Changes are continuously streamed to S3 every 10 seconds
- Full snapshots are created every 24 hours
- Old snapshots are cleaned up after 7 days

### On Failure/Recovery

If a container crashes and is restarted elsewhere:
1. The new container starts up
2. Finds no local database files
3. Restores the latest version from S3 (typically within seconds of the last write)
4. Continues operation with minimal data loss

## Benefits

### Stateless Containers
- No need for persistent volumes
- Containers can be destroyed and recreated freely
- Easy horizontal scaling (though SQLite is still single-writer)

### Disaster Recovery
- Point-in-time recovery to any point within the 7-day retention window
- Automatic backups without manual intervention
- Geographic redundancy (if using S3 with replication)

### Cost Efficiency
- S3 storage is cheaper than block storage for backups
- No need for complex backup scripts or cron jobs
- Minimal performance impact

## Manual Operations

### List Available Backups

```bash
bundle exec litestream generations -config config/litestream.yml storage/production.sqlite3
```

### Restore to Specific Point in Time

```bash
# Restore to specific timestamp
bundle exec litestream restore -config config/litestream.yml -timestamp 2024-01-01T12:00:00Z storage/production.sqlite3

# Restore to specific generation
bundle exec litestream restore -config config/litestream.yml -generation <generation-id> storage/production.sqlite3
```

### View Snapshots

```bash
bundle exec litestream snapshots -config config/litestream.yml storage/production.sqlite3
```

## Testing

Run the Litestream integration tests:

```bash
bundle exec rspec spec/lib/litestream_spec.rb
```

## Troubleshooting

### Restore Fails on Startup

If you see "No backup found in S3 or restore failed":
- This is normal for first-time setup
- The application will create a new database
- Future restores will work once replication starts

### Replication Not Working

Check the Litestream process logs:
```bash
# In the container
ps aux | grep litestream
```

Verify S3 credentials:
```bash
bundle exec litestream databases -config config/litestream.yml
```

### Performance Issues

If replication impacts performance:
- Increase `sync-interval` in `config/litestream.yml` (trade freshness for performance)
- Ensure S3 endpoint is geographically close to your application
- Monitor S3 API request costs

## Further Reading

- [Litestream Documentation](https://litestream.io/)
- [Litestream Ruby Gem](https://github.com/fractaledmind/litestream-ruby)
- [SQLite in Production](https://blog.wesleyac.com/posts/consider-sqlite)
