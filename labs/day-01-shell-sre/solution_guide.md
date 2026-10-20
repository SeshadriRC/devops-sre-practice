# Day 1 Deep-Dive: SRE Defensive Shell Patterns

This guide breaks down the 5 critical engineering flaws in [`legacy_watchdog.sh`](file:///mnt/c/Myfolder/MyProjects/devops-sre-practice/labs/day-01-shell-sre/legacy_watchdog.sh) and how they are solved in [`production_watchdog.sh`](file:///mnt/c/Myfolder/MyProjects/devops-sre-practice/labs/day-01-shell-sre/production_watchdog.sh).

---

## 1. Defensive Bash Strict Mode

### The Problem
By default, Bash continues executing even when commands fail, allows unset variables to evaluate to empty strings, and ignores intermediate pipe failures.
```bash
# In legacy script:
STATUS=$(curl -s $SERVICE_URL | grep "UP" | awk '{print $2}')
```
If `curl` fails with a connection timeout or DNS error (exit code `6` or `28`), `grep` gets empty input and exits with `1`, but `awk` exits with `0`. The entire line returns `0`, tricking the script into thinking the command succeeded!

### The SRE Solution
```bash
set -euo pipefail
IFS=$'\n\t'
```
* **`-e` (`errexit`)**: Exit immediately if any command returns a non-zero exit code.
* **`-u` (`nounset`)**: Treat unset variables as fatal errors. Prevents typos from creating blank strings.
* **`-o pipefail`**: The return code of a pipeline (`cmd1 | cmd2 | cmd3`) reflects the **rightmost command that returned an error**, not just the last command.
* **`IFS=$'\n\t'`**: Internal Field Separator set to newline and tab only. Prevents space characters in filenames/strings from causing unexpected word splitting.

---

## 2. Signal Traps (`trap`) & Graceful Cleanup

### The Problem
In production, scripts get killed by:
* OOM killer (`SIGKILL` - cannot be trapped, but kernel handles cleanup)
* System shutdown or pod termination (`SIGTERM`)
* Developer interrupts (`Ctrl+C` / `SIGINT`)
* Unexpected script crashes (`EXIT`)

In the legacy script, temporary files and locks were removed at the very end:
```bash
rm -f $LOCK_FILE
```
If the process was terminated before reaching this line, the lock file stayed permanently on disk. Subsequent cron runs saw the lock and aborted forever (**stale lock incident**).

### The SRE Solution
```bash
cleanup() {
    local exit_code=$?
    # Clean up temp workspaces
    [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR}" ]] && rm -rf "${TEMP_DIR}"
    # Close lock file descriptor
    eval "exec ${LOCK_FD}>&-" 2>/dev/null || true
    exit "${exit_code}"
}

# Trap covers normal exit, Ctrl+C (INT), and termination (TERM)
trap cleanup EXIT INT TERM
```
* **`trap ... EXIT` is special**: It fires on *any* exit (normal completion, error exit due to `set -e`, or signals that terminate the shell).
* Capturing `$?` ensures the original exit code is preserved.

---

## 3. Atomic Concurrency Control (`flock` vs File Checks)

### The Problem
The legacy script used:
```bash
if [ -f $LOCK_FILE ]; then
    exit 1
fi
echo $$ > $LOCK_FILE
```
This suffers from **TOCTOU (Time-of-Check to Time-of-Use)** race conditions:
1. Process A checks `[ -f $LOCK_FILE ]` (returns false).
2. Before Process A creates the file, Process B runs the check (returns false).
3. Both processes write their PID and run simultaneously, causing race conditions or corrupted data.
4. If a server crashes, the file remains, requiring manual intervention to delete.

### The SRE Solution: Kernel File Descriptor Locking (`flock`)
```bash
readonly LOCK_FD=200
readonly LOCK_FILE="/tmp/service_watchdog.lock"

# Open file descriptor for the lock file
eval "exec ${LOCK_FD}>\"${LOCK_FILE}\""

# Acquire non-blocking exclusive lock (-n)
if ! flock -n "${LOCK_FD}"; then
    log "WARN" "Another instance is running. Exiting cleanly."
    exit 0
fi
```
### Why `flock` is the Gold Standard:
1. **Kernel-Enforced**: Handled atomically inside the Linux kernel (`sys_flock`).
2. **Crash-Resilient**: When a process dies (even with `SIGKILL` or kernel panic), the kernel automatically closes all open file descriptors and **releases the lock immediately**. No stale lock files ever!
3. **Exit Code 0 vs 1**: When another cron instance is still running, exiting with `0` prevents triggering noisy cron email alerts, reserving alerts for actual failures.

---

## 4. Bounded Retries with Exponential Backoff

### The Problem
```bash
while [ "$STATUS" != "HEALTHY" ]; do
    sleep 2
    # retry forever...
done
```
If the database or dependent service is down for hours:
* The script loops infinitely.
* Every 5 minutes, cron spawns another watchdog.
* Eventually, the machine exhausts all available PIDs or memory, crashing the entire host (**thundering herd / PID exhaustion**).

### The SRE Solution
Always enforce a **maximum retry limit** and **exponential backoff**:
```bash
readonly MAX_RETRIES=4
readonly INITIAL_BACKOFF_SECS=2
attempt=1

while [[ ${attempt} -le ${MAX_RETRIES} ]]; do
    if check_health; then
        break
    fi
    
    if [[ ${attempt} -lt ${MAX_RETRIES} ]]; then
        # Exponential backoff formula: 2s, 4s, 8s...
        backoff=$(( INITIAL_BACKOFF_SECS * (2 ** (attempt - 1)) ))
        sleep "${backoff}"
    fi
    ((attempt++))
done
```
* **Bounded execution**: The script is mathematically guaranteed to finish in a predictable timeframe (under ~30 seconds).
* **Backoff**: Gives the recovering service time to restart without hammering it with requests.

---

## 5. Guarded Variable Expansion & Deletion

### The Problem
```bash
TARGET_DIR=$TEMP_DIR
rm -rf $TARGET_DIR/*
```
If `$TEMP_DIR` failed to initialize (or was misspelled), `TARGET_DIR` becomes empty.
The command evaluates to:
```bash
rm -rf /*
```
This is one of the most common causes of catastrophic self-inflicted production outages.

### The SRE Solution
1. Use parameter expansion assertion:
   ```bash
   readonly TARGET_DIR="${TEMP_DIR:?CRITICAL: TARGET_DIR is unset or empty!}"
   ```
   If `TEMP_DIR` is empty or unset, Bash immediately prints the error and aborts before running anything.
2. Use directory checks and `find -delete` instead of wildcard globbing:
   ```bash
   if [[ -d "${TARGET_DIR}" ]]; then
       find "${TARGET_DIR}" -mindepth 1 -delete
   fi
   ```

---

## Summary: SRE Checklist for Any Shell Script
- [x] `set -euo pipefail` and `IFS=$'\n\t'` enabled.
- [x] Structured logs with ISO 8601 UTC timestamps.
- [x] Signal cleanup handled via `trap cleanup EXIT INT TERM`.
- [x] Single-instance concurrency enforced via `flock`.
- [x] Network calls guarded with strict timeouts (`--connect-timeout`, `--max-time`).
- [x] Loops bounded with max retries and exponential backoff.
- [x] Destructive commands guarded with `${VAR:?error}`.
