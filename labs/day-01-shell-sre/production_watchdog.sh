#!/usr/bin/env bash
# ==============================================================================
# SRE Production-Grade Service Watchdog
# 
# Demonstrates:
# 1. Strict mode (set -euo pipefail, IFS)
# 2. Kernel-level non-blocking atomic locking via flock (auto-released on exit)
# 3. Graceful signal trapping (cleanup on EXIT, SIGINT, SIGTERM)
# 4. Bounded retries with exponential backoff and timeout
# 5. Guarded parameter expansion to prevent accidental destructive deletes
# 6. Structured logging with ISO 8601 timestamps and severity levels
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Defensive Bash Strict Mode
# ------------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# 2. Configuration & Constants
# ------------------------------------------------------------------------------
readonly SERVICE_URL="http://127.0.0.1:8080/health"
readonly LOCK_FILE="/tmp/service_watchdog.lock"
readonly LOCK_FD=200
readonly MAX_RETRIES=4
readonly INITIAL_BACKOFF_SECS=2
readonly REQUEST_TIMEOUT_SECS=3

# Structured logging function
log() {
    local level="$1"
    shift
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    echo "{\"timestamp\":\"${timestamp}\",\"level\":\"${level}\",\"message\":\"$*\"}"
}

# ------------------------------------------------------------------------------
# 3. Temporary Workspace & Signal Trapping
# ------------------------------------------------------------------------------
TEMP_DIR=""

cleanup() {
    local exit_code=$?
    log "INFO" "Executing cleanup trap (Exit code: ${exit_code})..."

    # Safely remove temporary directory if it exists
    if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR}" ]]; then
        rm -rf "${TEMP_DIR}"
        log "INFO" "Cleaned up temporary workspace: ${TEMP_DIR}"
    fi

    # Release flock file descriptor
    eval "exec ${LOCK_FD}>&-" 2>/dev/null || true

    log "INFO" "Watchdog process finished."
    exit "${exit_code}"
}

# Trap unexpected exits, interrupts (Ctrl+C), and termination signals (SIGTERM)
trap cleanup EXIT INT TERM

# Create temporary directory safely
TEMP_DIR="$(mktemp -d -t watchdog_work_XXXXXX)"
log "INFO" "Allocated temporary workspace: ${TEMP_DIR}"

# ------------------------------------------------------------------------------
# 4. Atomic Concurrency Control (flock)
# ------------------------------------------------------------------------------
# Open lock file descriptor
eval "exec ${LOCK_FD}>\"${LOCK_FILE}\""

# Attempt non-blocking exclusive lock (-n)
# If another cron job is already running, exit cleanly (0) to avoid alert fatigue.
if ! flock -n "${LOCK_FD}"; then
    log "WARN" "Another instance of watchdog is currently active. Exiting peacefully."
    # Unset TEMP_DIR so trap doesn't warn unnecessarily
    exit 0
fi

log "INFO" "Acquired exclusive execution lock on file descriptor ${LOCK_FD}."

# ------------------------------------------------------------------------------
# 5. Health Check Function (Bounded curl with timeout)
# ------------------------------------------------------------------------------
check_health() {
    local http_status
    # Use curl with maximum connection and total timeouts
    # -s: silent, -o /dev/null: discard output, -w: extract HTTP code
    http_status=$(curl --silent \
                       --connect-timeout "${REQUEST_TIMEOUT_SECS}" \
                       --max-time "${REQUEST_TIMEOUT_SECS}" \
                       --output /dev/null \
                       --write-out "%{http_code}" \
                       "${SERVICE_URL}" || echo "000")

    if [[ "${http_status}" == "200" ]]; then
        return 0
    else
        log "WARN" "Health check returned HTTP status: ${http_status}"
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 6. Bounded Retries with Exponential Backoff
# ------------------------------------------------------------------------------
attempt=1
service_healthy=false

while [[ ${attempt} -le ${MAX_RETRIES} ]]; do
    log "INFO" "Checking service health (Attempt ${attempt}/${MAX_RETRIES})..."
    
    if check_health; then
        log "INFO" "Service responded with 200 OK. System is healthy."
        service_healthy=true
        break
    fi

    if [[ ${attempt} -lt ${MAX_RETRIES} ]]; then
        # Exponential backoff formula: initial * 2^(attempt - 1)
        # e.g., 2s, 4s, 8s
        backoff=$(( INITIAL_BACKOFF_SECS * (2 ** (attempt - 1)) ))
        log "WARN" "Service unhealthy. Simulating restart and sleeping ${backoff}s before retry..."
        
        # In real production, trigger restart command / systemctl here:
        # systemctl restart my-service || true
        
        sleep "${backoff}"
    fi

    attempt=$(( attempt + 1 ))
done

if [[ "${service_healthy}" != "true" ]]; then
    log "ERROR" "CRITICAL: Service remained unhealthy after ${MAX_RETRIES} attempts. Raising alert!"
    # In production, trigger PagerDuty/Alertmanager webhook or write to metrics
    exit 1
fi

# ------------------------------------------------------------------------------
# 7. Safe File Operations (Guarded Deletion)
# ------------------------------------------------------------------------------
# Notice: Instead of dangerous `rm -rf $TARGET_DIR/*`,
# we ensure the variable is defined and exists before removing.
readonly TARGET_DIR="${TEMP_DIR:?CRITICAL: TARGET_DIR is unset or empty!}"

if [[ -d "${TARGET_DIR}" ]]; then
    # Delete contents safely without risk of globbing to /*
    find "${TARGET_DIR}" -mindepth 1 -delete
    log "INFO" "Safely purged temp directory contents: ${TARGET_DIR}"
fi

log "INFO" "Watchdog verification completed successfully."
exit 0
