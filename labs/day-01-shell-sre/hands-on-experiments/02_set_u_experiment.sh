#!/usr/bin/env bash
# ==============================================================================
# Experiment 2: Why we need 'set -u' (Unbound variable protection)
# Run this script: bash 02_set_u_experiment.sh
# ==============================================================================

echo "========================================="
echo "PART A: Running WITHOUT 'set -u'"
echo "========================================="
TARGET_FOLDER="/tmp/safe_folder"

# Notice the TYPO here: TARGET_FLODER instead of TARGET_FOLDER
echo "What Bash sees: rm -rf ${TARGET_FLODER}/*"
echo "Notice it evaluated to: rm -rf /* (CATASTROPHIC!)"
echo ""

echo "========================================="
echo "PART B: Running WITH 'set -u'"
echo "========================================="
set -u

# Bash will halt here immediately and refuse to run
echo "Trying to use the misspelled variable: $TARGET_FLODER"
echo "You will never reach this line!"
