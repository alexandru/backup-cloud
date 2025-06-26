# Backup Cloud - OneDrive to NextCloud

A Docker container that periodically backs up files from OneDrive to NextCloud using `rclone`.

## Features

- Lightweight Alpine-based image
- Uses the latest version of `rclone`
- Configurable schedule (cron expression)
- Configurable source and destination paths
- Detailed logging of backup operations

## Usage

### Building the Image

```bash
docker build -t backup-cloud .
```

### Running the Container

```bash
docker run -d \
  -v "$HOME/.config/rclone/rclone.conf:/rclone.conf:ro" \
  -e RCLONE_SOURCE_PATH="onedrive:" \
  -e RCLONE_DESTINATION_PATH="cloud:OneDrive" \
  -e BACKUP_SCHEDULE="0 3 * * *" \
  -e BACKUP_DIR="cloud:Backups/OneDrive" \
  -e TZ="Europe/Bucharest" \
  --name backup-cloud \
  ghcr.io/alexandru/backup-cloud
```

### Environment Variables

- `RCLONE_SOURCE_PATH`: Source path for backups (default: `onedrive:`)
- `RCLONE_DESTINATION_PATH`: Destination path for backups (default: `nextcloud:`)
- `BACKUP_SCHEDULE`: Cron schedule expression (default: `0 3 * * *` - 3 AM daily)
  - Set to `now` to run a one-time backup and exit
  - To run at 15:01 (3:01 PM), use: `1 15 * * *`
- `RCLONE_SYNC_PARAMS`: Additional parameters for rclone sync command (default: `--delete-excluded -c --track-renames --onedrive-hash-type sha1`)
- `BACKUP_DIR`: If specified, enables rclone's backup-dir functionality with timestamped subdirectories (e.g., set to `nextcloud:Backups/Versions` to store changed files)

### Setting up rclone.conf

Before using this container, you need to configure `rclone` with your cloud storage credentials:

1. Install `rclone` on your local machine
2. Run `rclone config` to set up your OneDrive and NextCloud connections
3. The config file is typically found at `~/.config/rclone/rclone.conf`
4. Mount this file to `/rclone.conf` as read-only when running the container

## Viewing Logs

```bash
docker logs backup-cloud
```

## Running a Backup Immediately

```bash
docker run --rm \
  -v "$HOME/.config/rclone/rclone.conf:/rclone.conf:ro" \
  -e RCLONE_SOURCE_PATH="onedrive:Documents" \
  -e RCLONE_DESTINATION_PATH="nextcloud:Backups/Documents" \
  -e BACKUP_SCHEDULE="now" \
  -e RCLONE_SYNC_PARAMS="--delete-excluded -c --track-renames --onedrive-hash-type sha1" \
  -e BACKUP_DIR="nextcloud:Backups/Versions" \
  -e TZ="Europe/Bucharest" \
  ghcr.io/alexandru/backup-cloud
```