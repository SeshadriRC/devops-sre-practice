#!/bin/bash
# ==============================================================================
# SRE Incident Scenario: Legacy Service Watchdog & Cleanup
# 
# Background:
# This script runs via cron every 5 minutes on production worker nodes.
# Last night, an alert fired at 03:00 AM because:
# 1. Disk ran out of space despite the cleanup script running.
# 2. A node got stuck forever in a deadlocked state with cron processes piling up.
# 3. An outage was masked because the script reported SUCCESS when an API call failed!
#
# YOUR MISSION:
# Review this script, identify the critical SRE/production anti-patterns,
# and refactor it into a robust, defensive production-grade Bash utility.
# ==============================================================================

LOG_FILE="/tmp/service_watchdog.log"
LOCK_FILE="/tmp/watchdog.lock"
TEMP_DIR="/tmp/watchdog_work"
SERVICE_URL="http://127.0.0.1:8080/health"

echo "Starting watchdog check at $(date)" >> $LOG_FILE

# Problem 1: Lock file logic (Race condition / Stale lock risk)
if [ -f $LOCK_FILE ]; then
    echo "Script already running, exiting..." >> $LOG_FILE
    exit 1
fi
echo $$ > $LOCK_FILE

mkdir -p $TEMP_DIR

# Problem 2: Pipeline failure masking
# If curl fails (connection refused or 500), curl returns non-zero,
# but grep/awk masks the exit code!
STATUS=$(curl -s $SERVICE_URL | grep "UP" | awk '{print $2}')
echo "Service status reported: $STATUS" >> $LOG_FILE

# Problem 3: Unbounded retry without backoff
while [ "$STATUS" != "HEALTHY" ]; do
    echo "Service unhealthy! Retrying..." >> $LOG_FILE
    # Simulating restart command
    echo "Restarting service..."
    sleep 2
    STATUS=$(curl -s $SERVICE_URL | grep "UP" | awk '{print $2}')
done

# Problem 4: Dangerous unquoted variable & potential disaster
TARGET_DIR=$TEMP_DIR
echo "Cleaning up temp files..."
rm -rf $TARGET_DIR/*

# Problem 5: Manual lock file removal (What happens if killed by SIGTERM or exit early?)
rm -f $LOCK_FILE
echo "Watchdog finished successfully at $(date)" >> $LOG_FILE
exit 0
