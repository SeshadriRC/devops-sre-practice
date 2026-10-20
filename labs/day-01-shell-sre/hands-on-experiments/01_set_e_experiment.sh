#!/usr/bin/env bash
# ==============================================================================
# Experiment 1: Why we need 'set -e'
# Run this script: bash 01_set_e_experiment.sh
# ==============================================================================

echo "========================================="
echo "PART A: Running WITHOUT 'set -e'"
echo "========================================="
echo "1. Attempting to list a non-existent directory..."
ls /non_existing_directory_xyz || true
echo "2. Bash continues executing next commands even though previous line failed!"
echo ""

echo "========================================="
echo "PART B: Running WITH 'set -e'"
echo "========================================="
set -e
echo "1. Attempting to list a non-existent directory..."
ls /non_existing_directory_xyz
echo "2. You will NEVER see this line because 'set -e' halted the script!"
