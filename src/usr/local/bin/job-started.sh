#!/usr/bin/env bash

# Runner job-started hook
# Runs before every job to ensure a clean environment for each workflow run.
# Configured via ACTIONS_RUNNER_HOOK_JOB_STARTED environment variable.
#
# This is essential for persistent (non-ephemeral) self-hosted runners where
# state from previous jobs can leak into subsequent ones.

set -euo pipefail

echo "::group::Runner job-started hook: cleaning up stale state"

# --- Gradle cleanup ---
# gradle/actions/setup-gradle copies init scripts into ~/.gradle/init.d/ but
# never removes them in its post-action step. On persistent runners these
# accumulate and interfere with subsequent Gradle builds that may use different
# Gradle versions or configurations.
GRADLE_USER_HOME="${GRADLE_USER_HOME:-${HOME}/.gradle}"
if [[ -d "${GRADLE_USER_HOME}/init.d" ]]; then
  echo "Cleaning Gradle init scripts from ${GRADLE_USER_HOME}/init.d/"
  rm -fv "${GRADLE_USER_HOME}"/init.d/gradle-actions.*.gradle \
         "${GRADLE_USER_HOME}"/init.d/gradle-actions.*.groovy 2>/dev/null || true
fi

# Clean up Gradle daemon logs and any leftover lock files that can cause
# "Could not create service" errors when Gradle versions change between jobs.
if [[ -d "${GRADLE_USER_HOME}/daemon" ]]; then
  echo "Stopping any orphaned Gradle daemons"
  find "${GRADLE_USER_HOME}/daemon" -name "*.lock" -delete 2>/dev/null || true
fi

# --- General state cleanup ---
# Remove any leftover tool caches or extracted archives from previous jobs.
# The _work/_tool directory is used by actions/setup-java, setup-node, etc.
# and can grow unbounded on persistent runners.
#
# Note: We do NOT delete the tool cache here because it speeds up subsequent
# jobs. If disk space becomes an issue, uncomment the following:
# rm -rf "${RUNNER_TOOL_CACHE:-/opt/hostedtoolcache}/"*

# Clean up any temporary files left by previous jobs
if [[ -n "${RUNNER_TEMP:-}" && -d "${RUNNER_TEMP}" ]]; then
  echo "Cleaning RUNNER_TEMP: ${RUNNER_TEMP}"
  rm -rf "${RUNNER_TEMP:?}"/* 2>/dev/null || true
fi

echo "::endgroup::"
