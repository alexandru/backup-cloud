#!/usr/bin/env python3

import json
import subprocess
import os
import sys

JOBS_FILE = os.environ.get('JOBS_FILE', '/config/jobs.json')

# Helper to extract remote name from rclone path (e.g., 'remote:path')
def get_remote(path):
    if ':' in path:
        return path.split(':', 1)[0]
    return None

def main():
    if not os.path.exists(JOBS_FILE):
        print(f"ERROR: Jobs file not found: {JOBS_FILE}", flush=True)
        sys.exit(1)
    with open(JOBS_FILE, 'r') as f:
        jobs = json.load(f)
    remotes = set()
    for job in jobs:
        src = job.get('source')
        dst = job.get('destination')
        src_remote = get_remote(src)
        dst_remote = get_remote(dst)
        if src_remote:
            remotes.add(src_remote)
        if dst_remote:
            remotes.add(dst_remote)
    # Get configured remotes
    result = subprocess.run(['rclone', 'config', 'show'], capture_output=True, text=True)
    config_remotes = set()
    for line in result.stdout.splitlines():
        if line.startswith('[') and line.endswith(']'):
            config_remotes.add(line[1:-1])
    error = False
    missing = remotes - config_remotes
    if missing:
        print(f"Missing remotes in rclone config: {', '.join(missing)}", flush=True)
        error = True
    else:
        print("All required remotes are configured.", flush=True)
    # Check connection/auth for each remote
    for remote in remotes:
        print(f"Checking remote: {remote}", flush=True)
        check = subprocess.run(['rclone', 'lsjson', f'{remote}:', '--max-depth', '1'], capture_output=True, text=True)
        if check.returncode != 0:
            print(f"  ERROR: Cannot access remote '{remote}': {check.stderr.strip()}", flush=True)
            error = True
        else:
            print(f"  OK: Remote '{remote}' is accessible.", flush=True)
    if error:
        sys.exit(1)

if __name__ == '__main__':
    main()
