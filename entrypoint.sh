#!/bin/bash

CONFIG_DIR="/root/.config/rclone"
mkdir -p $CONFIG_DIR

# Copy rclone config if mounted
if [ -f "/config/rclone.conf" ]; then
    echo "Found rclone config at /config/rclone.conf, copying to $CONFIG_DIR/rclone.conf"
    cp /config/rclone.conf $CONFIG_DIR/rclone.conf
fi

# Initial check to ensure rclone is properly configured
if ! rclone listremotes >/dev/null 2>&1; then
    echo "ERROR: rclone is not configured properly or no remotes are defined. Please mount a config file to /config/rclone.conf."
    exit 1
fi

echo "Backup container started"
echo "Backup schedule: $BACKUP_SCHEDULE"

# If BACKUP_SCHEDULE is "now", run once and exit
if [ "$BACKUP_SCHEDULE" = "now" ]; then
    echo "Running one-time backup for all jobs in jobs.json..."
    python3 /app/run-sync-jobs.py
    exit $?
fi

# Create crontab file
mkdir -p /etc/crontabs
echo "$BACKUP_SCHEDULE python3 /app/run-sync-jobs.py" > /etc/crontabs/root
chmod 0644 /etc/crontabs/root

# If the script is called with the run_now parameter, execute backup directly
if [ "$1" = "run_now" ]; then
    python3 /app/run-sync-jobs.py
    exit $?
fi

# Set /etc/localtime if TZ is set and the zoneinfo file exists
if [ -n "$TZ" ]; then
    echo "TZ environment variable is set to: $TZ"
    if [ -f "/usr/share/zoneinfo/$TZ" ]; then
        ln -sf "/usr/share/zoneinfo/$TZ" /etc/localtime
    else
        echo "WARNING: /usr/share/zoneinfo/$TZ does not exist. Timezone will not be set."
    fi
else
    echo "TZ environment variable is not set."
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
exec /usr/sbin/crond -f -l 8
