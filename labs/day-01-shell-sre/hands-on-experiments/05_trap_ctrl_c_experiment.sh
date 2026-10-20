#!/usr/bin/env bash
# ==============================================================================
# Experiment 5: Catching Ctrl+C (SIGINT) with trap
# Run this script: bash 05_trap_ctrl_c_experiment.sh
# Press Ctrl+C while it is running to see trap catch it!
# ==============================================================================

on_interrupt() {
    echo ""
    echo "========================================="
    echo ">>> TRAP: User pressed Ctrl+C (SIGINT)! <<<"
    echo "Gracefully stopping processes before exit..."
    echo "Clean exit completed."
    echo "========================================="
    exit 130
}

trap on_interrupt INT

echo "Long-running process started..."
echo "PRESS [Ctrl+C] to test the trap!"

for i in {1..10}; do
    echo "Working... ($i/10 seconds)"
    sleep 1
done

echo "Finished without interruption."
