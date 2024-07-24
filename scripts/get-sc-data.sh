#!/usr/bin/env bash

set -e

# Requires:
#   COMPONENT_NAME
#   SERVICE_CATALOGUE_API_KEY

# Outputs (all need to be populated in the Service Catalogue)
#   component_description
#   component_github_template_repo
#   component_github_project_teams_write
#   component_github_project_teams_admin
#   component_github_project_branch_protection_restricted_teams
#   component_circleci_project_k8s_namespace
#   component_circleci_context_k8s_namespaces
#   component_jira_project_keys
#   product_hmpps_product_id

# Setup SC session
SC_API_ENDPOINT="https://service-catalogue.hmpps.service.justice.gov.uk/v1"

SC_HTTPIE_SESSION="/tmp/.httpie_session_sc.json"
SC_HTTPIE_OPTS=("--check-status" "--timeout=4.5" "--session-read-only=${SC_HTTPIE_SESSION}")

echo "Service catalogue API_KEY is ${SERVICE_CATALOGUE_API_KEY:0:5}..${SERVICE_CATALOGUE_API_KEY:250:255}" >&2

# Setup httpie session, enable preview API features
if ! OUTPUT=$(http --check-status --ignore-stdin --session=${SC_HTTPIE_SESSION} "${SC_API_ENDPOINT}/components" "Authorization: Bearer ${SERVICE_CATALOGUE_API_KEY}"); then
  echo "Unable to talk to Service Catalogue API, check connectivity and API token value set correctly." >&2
  echo "$OUTPUT" >&2
  exit 1
else
  echo "Connected to Service Catalogue API" >&2
fi

http_sc() {
  echo "Command is http --debug ${SC_HTTPIE_OPTS[@]} ${SC_API_ENDPOINT}/$@" >&2
  http "${SC_HTTPIE_OPTS[@]}" "${SC_API_ENDPOINT}/$@"
}

echo "COMPONENT_NAME is ${COMPONENT_NAME}" >&2

#COMPONENT_SETTINGS=$(http_sc "components?filters[name][\$eq]=${COMPONENT_NAME}&populate=*")
COMPONENT_SETTINGS=$(http_sc "components?filters[name][%24eq]=${COMPONENT_NAME}&populate[0]=product&populate[1]=environments")

if [ $(echo $COMPONENT_SETTINGS | jq ".meta.pagination.total") -eq 0 ]
then 
  echo "${COMPONENT_NAME} could not be found in the Service Catalogue - please add it first."
  exit 1
else
  component_description="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.description' | tr -d '\"')"
  component_github_template_repo="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.github_template_repo' | tr -d '\"')"
  component_github_project_teams_write="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.github_project_teams_write // []' | tr -d '\n')"
  component_github_project_teams_admin="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.github_project_teams_admin // []' | tr -d '\n')"
  component_github_project_teams_maintain="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.github_project_teams_maintain' | tr -d '\n')"
  component_github_project_branch_protection_restricted_teams="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.github_project_branch_protection_restricted_teams // []' | tr -d '\n')"
  component_github_project_visibility="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.github_project_visibility // "public"'  | tr -d '\"')"
  component_jira_project_keys="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.jira_project_keys // []' | tr -d '\n')"
  product_hmpps_product_id="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.product.data.attributes.p_id' | tr -d '\"')"
  namespace_details="$(echo $COMPONENT_SETTINGS | jq '.data[0].attributes.environments' )"
  component_circleci_project_k8s_namespace="$(echo $namespace_details | jq '.[] | select ( .name=="dev").namespace'  | tr -d '\"')"
  if [ $(echo $namespace_details | jq '.[] | select ( .name!="dev").namespace' | wc -l) -gt 0 ]
  then
    component_circleci_context_k8s_namespaces="["
    for each_namespace in $(echo $namespace_details | jq '.[] | select ( .name!="dev").namespace' | sed "s/${COMPONENT_NAME}-//g")
    do 
      component_circleci_context_k8s_namespaces="${component_circleci_context_k8s_namespaces} { \"env_name\" : ${each_namespace} },"
    done
    component_circleci_context_k8s_namespaces=$(echo $component_circleci_context_k8s_namespaces | sed 's/,$/\]/g')
  else
    component_circleci_context_k8s_namespaces="[]"
  fi
     

# Generate the outputs of the action
  echo "component_description=${component_description}"
  echo "component_github_template_repo=${component_github_template_repo}"
  echo "component_github_project_teams_write=${component_github_project_teams_write}"
  echo "component_github_project_teams_admin=${component_github_project_teams_admin}"
  echo "component_github_project_teams_maintain=${component_github_project_teams_maintain}"
  echo "component_github_project_branch_protection_restricted_teams=${component_github_project_branch_protection_restricted_teams}"
  echo "component_github_project_visibility=${component_github_project_visibility}"
  echo "component_jira_project_keys=${component_jira_project_keys}"
  echo "product_hmpps_product_id=${product_hmpps_product_id}"
  echo "component_circleci_project_k8s_namespace=${component_circleci_project_k8s_namespace}"
  echo "component_circleci_context_k8s_namespaces=${component_circleci_context_k8s_namespaces}"
fi