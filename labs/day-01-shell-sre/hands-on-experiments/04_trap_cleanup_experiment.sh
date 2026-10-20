#!/usr/bin/env bash
# ==============================================================================
# Experiment 4: How 'trap' cleans up files even on unexpected script crashes
# Run this script: bash 04_trap_cleanup_experiment.sh
# ==============================================================================

TEST_FILE="/tmp/sre_trap_demo_$$.tmp"

cleanup() {
    local exit_code=$?
    echo ""
    echo "========================================="
    echo ">>> TRAP TRIGGERED! (Exit code: $exit_code) <<<"
    echo "========================================="
    if [[ -f "$TEST_FILE" ]]; then
        echo "Removing temporary file: $TEST_FILE"
        rm -f "$TEST_FILE"
        echo "Cleanup completed successfully!"
    fi
}

# The trap catches EXIT (whether successful or due to error)
trap cleanup EXIT

echo "1. Creating temporary file at: $TEST_FILE"
touch "$TEST_FILE"
ls -l "$TEST_FILE"
echo ""

echo "2. Simulating a catastrophic script crash (set -e with bad command)..."
set -e
cat /folder_that_does_not_exist_will_crash_script

echo "3. You will NEVER see this line because the script crashed!"
