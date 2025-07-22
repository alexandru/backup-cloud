#!/usr/bin/env python3

import json
import subprocess
import datetime
import os
import sys

JOBS_FILE = os.environ.get('JOBS_FILE', '/config/jobs.json')
PID_FILE = '/var/run/run-sync-jobs.pid'

# Check for existing PID file and running process (no third-party libraries)
def pid_exists(pid):
    if pid <= 0:
        return False
    try:
        os.kill(pid, 0)
    except OSError:
        return False
    else:
        return True

def main():
    if not os.path.exists(JOBS_FILE):
        print(f"ERROR: Jobs file not found: {JOBS_FILE}", flush=True)
        sys.exit(1)

    with open(JOBS_FILE, 'r') as f:
        jobs = json.load(f)

    timestamp = datetime.datetime.now().strftime('%Y-%m-%d.%H-%M-%S')
    for job in jobs:
        source = job.get('source')
        destination = job.get('destination')
        sync_params = job.get('sync_params', '')
        backup_dir = job.get('backup_dir', '')
        backup_dir_param = f'--backup-dir "{backup_dir}/{timestamp}"' if backup_dir else ''

        print(f"[{datetime.datetime.now()}] ------------------------------------------------", flush=True)
        cmd = f'rclone sync "{source}" "{destination}" -v --transfers 4 --checkers 8 {sync_params} {backup_dir_param}'
        print(f"[{datetime.datetime.now()}] Executing command:", flush=True)
        print(cmd, flush=True)
        result = subprocess.run(cmd, shell=True)
        if result.returncode == 0:
            print(f"[{datetime.datetime.now()}] Backup completed successfully", flush=True)
        else:
            print(f"[{datetime.datetime.now()}] Backup failed with exit code {result.returncode}", file=sys.stderr, flush=True)

if __name__ == '__main__':
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, 'r') as pf:
                existing_pid = int(pf.read().strip())
            if existing_pid != os.getpid() and pid_exists(existing_pid):
                print(f"Another instance is already running with PID {existing_pid}. Exiting.", flush=True)
                sys.exit(0)
        except Exception:
            pass  # PID file corrupt or unreadable

    # Write current PID to file
    with open(PID_FILE, 'w') as pf:
        pf.write(str(os.getpid()))
    try:
        main()
    finally:
        if os.path.exists(PID_FILE):
            os.remove(PID_FILE)  # Clean up PID file on exit
