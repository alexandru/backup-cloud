#!/bin/bash

# Function to run the backup
run_backup() {
    echo "[$(date)] Starting backup from $RCLONE_SOURCE_PATH to $RCLONE_DESTINATION_PATH"
    
    # Set up backup directory parameter if provided
    BACKUP_DIR_PARAM=""
    if [ -n "$BACKUP_DIR" ]; then
        TIMESTAMP=$(date +"%Y-%m-%d.%H-%M-%S")
        BACKUP_DIR_PARAM="--backup-dir \"$BACKUP_DIR/$TIMESTAMP\""
        echo "[$(date)] Using backup directory: $BACKUP_DIR/$TIMESTAMP"
    fi

    # Run rclone with logging and custom parameters
    eval "rclone sync \"$RCLONE_SOURCE_PATH\" \"$RCLONE_DESTINATION_PATH\" \
        --progress \
        --transfers 4 \
        --checkers 8 \
        -v \
        $RCLONE_SYNC_PARAMS \
        $BACKUP_DIR_PARAM"
    
    backup_status=$?
    if [ $backup_status -eq 0 ]; then
        echo "[$(date)] Backup completed successfully"
    else
        echo "[$(date)] Backup failed with exit code $backup_status"
    fi
}

# Initial check to ensure rclone is properly configured
if ! rclone config show; then
    echo "ERROR: rclone is not configured properly. Please mount a config file to /root/.config/rclone/rclone.conf"
    exit 1
fi

echo "Backup container started"
echo "Backup schedule: $BACKUP_SCHEDULE"
echo "Source: $RCLONE_SOURCE_PATH"
echo "Destination: $RCLONE_DESTINATION_PATH"
echo "Sync parameters: $RCLONE_SYNC_PARAMS"
if [ -n "$BACKUP_DIR" ]; then
    echo "Backup directory: $BACKUP_DIR (with timestamped subfolders)"
else
    echo "Backup directory: Not configured"
fi

# If BACKUP_SCHEDULE is "now", run once and exit
if [ "$BACKUP_SCHEDULE" = "now" ]; then
    echo "Running one-time backup..."
    run_backup
    exit 0
fi

# Create crontab file
echo "$BACKUP_SCHEDULE /app/backup.sh run_now" > /tmp/backup-crontab
crontab /tmp/backup-crontab
rm /tmp/backup-crontab

# If the script is called with the run_now parameter, execute backup directly
if [ "$1" = "run_now" ]; then
    run_backup
    exit 0
fi

# Start cron in the foreground
echo "Starting cron service..."
exec crond -f -d 8