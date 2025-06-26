# Use Alpine Linux as base for a slim image
FROM alpine:latest

# Install necessary packages
RUN apk add --no-cache \
    ca-certificates \
    tzdata \
    curl \
    unzip \
    bash \
    busybox-suid

# Install the latest version of rclone
RUN curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cd rclone-*-linux-amd64 && \
    cp rclone /usr/bin/ && \
    chmod 755 /usr/bin/rclone && \
    cd .. && \
    rm -rf rclone-*-linux-amd64 rclone-current-linux-amd64.zip

# Set environment variables with defaults
ENV RCLONE_SOURCE_PATH="onedrive:"
ENV RCLONE_DESTINATION_PATH="nextcloud:"
ENV BACKUP_SCHEDULE="0 3 * * *"
ENV RCLONE_SYNC_PARAMS="--delete-excluded -c --track-renames --onedrive-hash-type sha1"
ENV BACKUP_DIR=""

# Copy script for backup execution
COPY backup.sh /app/backup.sh
RUN chmod +x /app/backup.sh

# Set working directory
WORKDIR /app

# Use a simple entrypoint script
CMD ["/app/backup.sh"]