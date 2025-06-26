# Backup Cloud - OneDrive to NextCloud

A Docker container that periodically backs up files, via `rclone`, from one remote to another (e.g., from OneDrive to NextCloud).

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

Or via `docker-compose.yml`:

```yaml
services:
  backup-cloud:
    image: ghcr.io/alexandru/backup-cloud
    container_name: backup-cloud
    environment:
      RCLONE_SOURCE_PATH: "onedrive:"
      RCLONE_DESTINATION_PATH: "cloud:OneDrive"
      BACKUP_SCHEDULE: "0 3 * * *"
      BACKUP_DIR: "cloud:Backups/OneDrive"
      TZ: "Europe/Bucharest"
    volumes:
      - "$HOME/.config/rclone/rclone.conf:/rclone.conf:ro"
```

### Environment Variables

- `RCLONE_SOURCE_PATH`: Source path for backups (default: `onedrive:`)
- `RCLONE_DESTINATION_PATH`: Destination path for backups (default: `nextcloud:`)
- `BACKUP_SCHEDULE`: Cron schedule expression (default: `0 3 * * *` - 3 AM daily)
  - Set to `now` to run a one-time backup and exit
  - To run at 15:01 (3:01 PM), use: `1 15 * * *`
- `RCLONE_SYNC_PARAMS`: Additional parameters for rclone sync command (default: `--delete-excluded -c --track-renames --onedrive-hash-type sha1`)
- `BACKUP_DIR`: If specified, enables rclone's backup-dir functionality with timestamped subdirectories (e.g., set to `nextcloud:Backups/Versions` to store changed files)
