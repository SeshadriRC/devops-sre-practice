#!/usr/bin/env bash
# ==============================================================================
# Experiment 3: Why we need 'set -o pipefail'
# Run this script: bash 03_pipefail_experiment.sh
# ==============================================================================

echo "========================================="
echo "PART A: Running Pipeline WITHOUT 'pipefail'"
echo "========================================="
# cat fails because file does not exist, but 'wc -l' succeeds and outputs 0 lines
cat /non_existent_file_12345.txt 2>/dev/null | wc -l
EXIT_CODE=$?
echo "Exit code without pipefail: $EXIT_CODE"
if [ $EXIT_CODE -eq 0 ]; then
    echo "DANGER: The script thinks the pipeline was SUCCESSFUL (exit 0)!"
fi
echo ""

echo "========================================="
echo "PART B: Running Pipeline WITH 'set -o pipefail'"
echo "========================================="
set -o pipefail
# With pipefail, the failure of 'cat' is not masked by 'wc -l'
cat /non_existent_file_12345.txt 2>/dev/null | wc -l || true
EXIT_CODE=${PIPESTATUS[0]}
echo "Pipeline caught failure! cat exit code was: $EXIT_CODE"
