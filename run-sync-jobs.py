import json
import subprocess
import datetime
import os
import sys

JOBS_FILE = os.environ.get('JOBS_FILE', '/config/jobs.json')

if not os.path.exists(JOBS_FILE):
    print(f"ERROR: Jobs file not found: {JOBS_FILE}")
    sys.exit(1)

with open(JOBS_FILE, 'r') as f:
    jobs = json.load(f)

for job in jobs:
    source = job.get('source')
    destination = job.get('destination')
    sync_params = job.get('sync_params', '')
    backup_dir = job.get('backup_dir', '')
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d.%H-%M-%S')
    backup_dir_param = f'--backup-dir "{backup_dir}/{timestamp}"' if backup_dir else ''

    cmd = f'rclone sync "{source}" "{destination}" -v --transfers 4 --checkers 8 {sync_params} {backup_dir_param}'
    print(f"[{datetime.datetime.now()}] Executing command:")
    print(cmd)
    result = subprocess.run(cmd, shell=True)
    if result.returncode == 0:
        print(f"[{datetime.datetime.now()}] Backup completed successfully")
    else:
        print(f"[{datetime.datetime.now()}] Backup failed with exit code {result.returncode}", file=sys.stderr)
