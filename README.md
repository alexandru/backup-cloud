# Backup Cloud

A Docker container that periodically backs up files, via `rclone`, from one remote to another (e.g., from OneDrive to NextCloud, or to local).

## Usage

### Building the Image

```bash
docker build -t backup-cloud .
```

### Running the Container

```bash
docker run \
  -v "$HOME/.config/rclone/rclone.conf:/config/rclone.conf:ro" \
  -v "$HOME/.config/backup-cloud/jobs.json:/config/jobs.json:ro" \
  -e BACKUP_SCHEDULE="0 3 * * *" \
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
      BACKUP_SCHEDULE: "0 3 * * *"
      TZ: "Europe/Bucharest"
    volumes:
      - "$HOME/.config/rclone/rclone.conf:/config/rclone.conf:ro"
      - "$HOME/.config/backup-cloud/jobs.json:/config/jobs.json:ro"
    healthcheck:
      test: ["CMD", "python", "/healthcheck.py"]
      interval: 5m
      timeout: 10s
      retries: 2
      start_period: 30s
```

> **Note:** The `BACKUP_SCHEDULE` environment variable sets the global cron schedule for all jobs in jobs.json. To run immediately, set `BACKUP_SCHEDULE=now`.

### jobs.json Example

Mount the `jobs.json` file in the `/config` directory:

```json
[
  {
    "source": "onedrive:",
    "destination": "cloud:OneDrive",
    "sync_params": "--delete-excluded -c --track-renames --onedrive-hash-type sha1",
    "backup_dir": "cloud:Backups/OneDrive"
  },
  {
    "source": "server:",
    "destination": "cloud:Server",
    "sync_params": "--delete-excluded -c --track-renames --onedrive-hash-type sha1",
  }
]
```
