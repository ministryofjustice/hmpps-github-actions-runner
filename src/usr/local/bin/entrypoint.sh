#!/usr/bin/env bash

set -euo pipefail

# Get the token
source /usr/local/bin/get_token.sh


ACTIONS_RUNNER_DIRECTORY="/actions-runner"
EPHEMERAL="${EPHEMERAL:-"false"}"

echo "Runner parameters:"
echo "  GitHub org: ${GH_ORG}"
echo "  Runner Name: $(hostname)"
echo "  Runner Labels: ${RUNNER_LABEL}"
echo "  Runner group: ${RUNNER_GROUP}"

echo "Obtaining registration token"
getRegistrationToken="${RUNNER_REG_TOKEN}"
export getRegistrationToken

echo "Checking if registration token exists"
if [[ -z "${getRegistrationToken}" ]]; then
  echo "Failed to obtain registration token"
  exit 1
else
  echo "Registration token obtained successfully"
  REPO_TOKEN="${getRegistrationToken}"
fi

if [[ "${EPHEMERAL}" == "true" ]]; then
  EPHEMERAL_FLAG="--ephemeral"
  trap 'echo "Shutting down runner"; exit' SIGINT SIGQUIT SIGTERM INT TERM QUIT
else
  EPHEMERAL_FLAG=""
fi

echo "Checking the runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" --check --url "https://github.com/${GH_ORG}" --pat "${GH_INSTALLATION_TOKEN}"

echo "Configuring runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/config.sh" ${EPHEMERAL_FLAG} \
  --unattended \
  --disableupdate \
  --url "https://github.com/${GH_ORG}" \
  --token "${REPO_TOKEN}" \
  --name "$(hostname)" \
  --labels "${RUNNER_LABEL}" \
  --runnergroup "${RUNNER_GROUP}"

echo "Setting the 'ready' flag for Kubernetes liveness probe"
touch /tmp/runner.ready

echo "Starting runner"
bash "${ACTIONS_RUNNER_DIRECTORY}/run.sh"
