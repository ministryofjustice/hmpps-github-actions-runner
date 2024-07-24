#!/usr/bin/env bash
# Modification of quayio.sh to be standalone as part of github actions
# Made by jamesH July 2024
# Version 0.0.1 - initial commit

set -e

echo -e "\n### QUAY.IO REPO SETUP ###"
# Required env vars, set by calling action
#GITHUB_REPO_NAME="" 
#QUAYIO_ORG="hmpps"
#GITHUB_REPO_DESCRIPTION=""
#GITHUB_ORG="ministryofjustice"
#CIRCLECI_TOKEN=""

#QUAY.IO parameters
QUAYIO_HTTPIE_SESSION="./.httpie_session_quayio.json"
QUAYIO_HTTPIE_OPTS=("--body" "--check-status" "--ignore-stdin" "--timeout=4.5" "--session-read-only=${QUAYIO_HTTPIE_SESSION}")
QUAYIO_API_ENDPOINT="https://quay.io/api/v1"

#CIRCLECI parameters
CIRCLECI_API_ENDPOINT="https://circleci.com/api/v2"
CIRCLECI_HTTPIE_SESSION="./.httpie_session_circleci.json"
CIRCLECI_HTTPIE_OPTS=("-b" "--check-status" "--ignore-stdin" "--timeout=60" "--session-read-only=${CIRCLECI_HTTPIE_SESSION}")
PROJECT_SLUG="gh/${GITHUB_ORG}/${GITHUB_REPO_NAME}" 

function http_quayio() {
  http "${QUAYIO_HTTPIE_OPTS[@]}" "$@"
}

function setup_quayio_session() {
  # Setup httpie quay.io session
if ! OUTPUT=$(http --check-status --ignore-stdin --session=${QUAYIO_HTTPIE_SESSION} "${QUAYIO_API_ENDPOINT}/organization/$QUAYIO_ORG" "Authorization: Bearer ${QUAYIO_TOKEN}"); then
  echo "Unable to talk to Quay.io API - check that the QUAYIO_TOKEN value is set correctly and permissions granted."
  echo "$OUTPUT"
  exit 1
fi
if [[ $(echo "$OUTPUT" | jq -r .is_admin) != 'true' ]]; then
  echo "QUAYIO_TOKEN is not an administrator of the $QUAYIO_ORG organisation"
  echo "$OUTPUT"
  exit 1
fi
}

function http_circleci() {
  http "${CIRCLECI_HTTPIE_OPTS[@]}" "$@"
}

function setup_circleci_session() {
  #setup httpie circleci session
if ! OUTPUT=$(http -b --check-status --session=${CIRCLECI_HTTPIE_SESSION} ${CIRCLECI_API_ENDPOINT}/me/collaborations "Circle-Token: ${CIRCLECI_TOKEN}"); then
  echo "Unable to talk to circleci API - check that the CIRCLECI_TOKEN value is set correctly and permissions granted."
  echo "$OUTPUT"
  exit 1
fi
}

function set_circleci_env_var {
  VAR_NAME=$1
  VAR_VALUE=$2
  echo "Setting env var on project ${PROJECT_SLUG}:"
  http_circleci POST "${CIRCLECI_API_ENDPOINT}/project/${PROJECT_SLUG}/envvar" \
    name="${VAR_NAME}" \
    value="${VAR_VALUE}"
}


echo "Entering update-quayio.sh - the description is: ${github_repo_description}"

# Set up the sessions
setup_quayio_session
setup_circleci_session
