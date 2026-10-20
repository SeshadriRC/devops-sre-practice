#!/usr/bin/env bash
# ==============================================================================
# Experiment 6: How 'flock' prevents duplicate cron jobs / race conditions
# ==============================================================================

LOCK_FILE="/tmp/sre_demo_flock.lock"
LOCK_FD=200

# Open file descriptor 200 pointing to the lock file
eval "exec ${LOCK_FD}>\"${LOCK_FILE}\""

echo "Process [PID: $$] is trying to acquire the lock..."

# Attempt non-blocking lock (-n)
if ! flock -n ${LOCK_FD}; then
    echo "❌ [PID: $$] REJECTED: Another job is ALREADY running! Exiting cleanly."
    exit 0
fi

echo "✅ [PID: $$] SUCCESS: Lock acquired! Running task for 5 seconds..."
sleep 5
echo "🏁 [PID: $$] Task finished. Lock released automatically by kernel."
