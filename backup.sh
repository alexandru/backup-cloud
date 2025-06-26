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

    # Construct the full rclone command
    RCLONE_CMD="rclone sync \"$RCLONE_SOURCE_PATH\" \"$RCLONE_DESTINATION_PATH\" \
        -v \
        --transfers 4 \
        --checkers 8 \
        $RCLONE_SYNC_PARAMS \
        $BACKUP_DIR_PARAM"
    
    # Print the full command for debugging
    echo "[$(date)] Executing command:"
    echo "$RCLONE_CMD"
    
    # Run rclone with logging and custom parameters
    eval "$RCLONE_CMD"
    
    backup_status=$?
    if [ $backup_status -eq 0 ]; then
        echo "[$(date)] Backup completed successfully"
    else
        echo "[$(date)] Backup failed with exit code $backup_status"
    fi
}

# Setup rclone configuration
CONFIG_DIR="/root/.config/rclone"
mkdir -p $CONFIG_DIR

# Check if config is mounted at alternative location
if [ -f "/rclone.conf" ]; then
    echo "Found rclone config at /rclone.conf, copying to $CONFIG_DIR/rclone.conf"
    cp /rclone.conf $CONFIG_DIR/rclone.conf
fi

# Initial check to ensure rclone is properly configured
if ! rclone config show; then
    echo "ERROR: rclone is not configured properly. Please mount a config file to /rclone.conf"
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
mkdir -p /etc/crontabs
echo "$BACKUP_SCHEDULE /app/backup.sh run_now" > /etc/crontabs/root
chmod 0644 /etc/crontabs/root

# If the script is called with the run_now parameter, execute backup directly
if [ "$1" = "run_now" ]; then
    run_backup
    exit 0
fi

# Set /etc/localtime if TZ is set and the zoneinfo file exists
if [ -n "$TZ" ] && [ -f "/usr/share/zoneinfo/$TZ" ]; then
    ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
fi

# Print timezone and current datetime information
if [ -f /etc/timezone ]; then
    TZ_DISPLAY=$(cat /etc/timezone)
elif [ -L /etc/localtime ]; then
    TZ_DISPLAY=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
else
    TZ_DISPLAY="UTC (default or unknown)"
fi
echo "Container timezone: $TZ_DISPLAY"
echo "Current date and time: $(date '+%Y-%m-%d %H:%M:%S %Z (%z)')"

# Start cron in the foreground
echo "Starting cron service..."
# Use busybox crond which is more container-friendly
exec /usr/sbin/crond -f -l 8