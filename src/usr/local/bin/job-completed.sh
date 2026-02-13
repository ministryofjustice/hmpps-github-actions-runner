#!/usr/bin/env bash

# Runner job-completed hook
# Runs after every job to clean up artifacts and state that actions leave behind.
# Configured via ACTIONS_RUNNER_HOOK_JOB_COMPLETED environment variable.
#
# This is essential for persistent (non-ephemeral) self-hosted runners where
# state from one job can leak into the next.

set -euo pipefail

echo "::group::Runner job-completed hook: post-job cleanup"

# --- Gradle cleanup ---
GRADLE_USER_HOME="${GRADLE_USER_HOME:-${HOME}/.gradle}"

# Remove init scripts left by gradle/actions/setup-gradle
if [[ -d "${GRADLE_USER_HOME}/init.d" ]]; then
  echo "Removing Gradle Actions init scripts from ${GRADLE_USER_HOME}/init.d/"
  rm -fv "${GRADLE_USER_HOME}"/init.d/gradle-actions.*.gradle \
         "${GRADLE_USER_HOME}"/init.d/gradle-actions.*.groovy 2>/dev/null || true
fi

# Stop any Gradle daemons spawned during the job to free memory and avoid
# version conflicts with the next job
if command -v gradle &>/dev/null || [[ -d "${GRADLE_USER_HOME}/daemon" ]]; then
  echo "Stopping Gradle daemons"
  # Find all wrapper scripts in the Gradle cache and use the newest one to stop daemons
  GRADLE_WRAPPER=$(find "${GRADLE_USER_HOME}/wrapper/dists" -name "gradle" -type f 2>/dev/null | head -1)
  if [[ -n "${GRADLE_WRAPPER:-}" && -x "${GRADLE_WRAPPER}" ]]; then
    "${GRADLE_WRAPPER}" --stop 2>/dev/null || true
  fi
  # Also forcefully kill any remaining daemon processes
  pkill -f 'GradleDaemon' 2>/dev/null || true
fi

# Clean out the home directory
  echo "Cleaning the home directory"
  rm -rf "${HOME}/.*" 2>/dev/null || true
  rm -rf "${HOME}/*" 2>/dev/null || true

# --- Workspace cleanup ---
# The runner's built-in cleanup should handle the _work directory, but
# sometimes large build outputs persist. Clean up common offenders.
if [[ -n "${GITHUB_WORKSPACE:-}" && -d "${GITHUB_WORKSPACE}" ]]; then
  echo "Cleaning workspace: ${GITHUB_WORKSPACE}"
  rm -rf "${GITHUB_WORKSPACE:?}"/* 2>/dev/null || true
fi

# --- RUNNER_TEMP cleanup ---
if [[ -n "${RUNNER_TEMP:-}" && -d "${RUNNER_TEMP}" ]]; then
  echo "Cleaning RUNNER_TEMP: ${RUNNER_TEMP}"
  rm -rf "${RUNNER_TEMP:?}"/* 2>/dev/null || true
fi

echo "::endgroup::"
