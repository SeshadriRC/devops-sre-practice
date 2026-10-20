# Day 1: Defensive SRE Shell Scripting & Incident Mitigation

## 🎯 Incident Scenario
You are an on-call SRE. A legacy watchdog script ([legacy_watchdog.sh](file:///mnt/c/Myfolder/MyProjects/devops-sre-practice/labs/day-01-shell-sre/legacy_watchdog.sh)) runs as a cron job every 5 minutes on application servers.

Last night, several incidents occurred across the cluster:
1. **Deadlock / Stale Lockout**: A node rebooted / crashed mid-execution. Because the lockfile was left on disk, the watchdog never ran again.
2. **Infinite Process Pileup**: When the monitored service went down permanently, the script entered an infinite loop. Subsequent cron jobs piled up until the host ran out of process IDs (PIDs).
3. **Silent Failure Masking**: A network partition occurred; `curl` failed, but downstream pipe commands masked the error code, reporting success.
4. **Catastrophic Deletion Risk**: `rm -rf $TARGET_DIR/*` was executed without variable existence validation.

---

## 🛠️ Your Objectives
Analyze [legacy_watchdog.sh](file:///mnt/c/Myfolder/MyProjects/devops-sre-practice/labs/day-01-shell-sre/legacy_watchdog.sh) and address the following 5 areas:

1. **Defensive Shell Boilerplate**:
   - What flags should be set at the top of every production Bash script and why?
2. **Signal Traps (`trap`)**:
   - How can you guarantee cleanup of temporary directories and lock files when the script exits, errors out, or receives `SIGTERM`/`SIGINT`?
3. **Atomic Concurrency Control**:
   - Why is `if [ -f $LOCK_FILE ]` unsafe (TOCTOU race condition)? How can you use `flock` or atomic operations instead?
4. **Retry Loop with Bounded Backoff**:
   - Replace the unbounded `while` loop with a maximum retry counter (e.g., 3-5 attempts) and backoff.
5. **Safe Variable Expansion**:
   - Prevent unbounded file deletion (`rm -rf`) if variables are empty or unset.
