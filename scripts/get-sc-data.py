#!/usr/bin/python3

import requests
import os
import json
import sys

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

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

SERVICE_CATALOGUE_API_KEY=os.getenv("SERVICE_CATALOGUE_API_KEY")
COMPONENT_NAME=os.getenv("COMPONENT_NAME")

eprint(f"Service catalogue API_KEY is {SERVICE_CATALOGUE_API_KEY[0:5]}..{SERVICE_CATALOGUE_API_KEY[250:255]}")

component_json=requests.get(f"{SC_API_ENDPOINT}/components/?filters[name][$eq]={COMPONENT_NAME}&populate[0]=product&populate[1]=environments").json()

# all the main components
component_list=['description','github_template_repo','github_project_teams_write','github_project_teams_admin',
                'github_project_teams_maintain','github_project_branch_protection_restricted_teams','jira_project_keys']
if component_json['meta']['pagination']['pageCount']>0:
    component_attributes=component_json['data'][0]['attributes']
#    eprint(json.dumps(component_attributes))
    for each_component in component_list:
       if each_component in component_attributes:
          if component_attributes[each_component]!=None:
            print(f'component_{each_component}={component_attributes[each_component]}')
          else:
            print(f'component_{each_component}=')
       else:
          print(f'component_{each_component}=')
    # extended field for product_id
    p_id=""
    if 'product' in component_attributes:
        if 'data' in component_attributes['product']:
            if 'attributes' in component_attributes['product']['data']:
                if 'p_id' in component_attributes['product']['data']['attributes']:
                    p_id=(component_attributes['product']['data']['attributes']['p_id'])
    print(f'product_hmpps_product_id={p_id}')
    # namespace goodness
    dev_namespace=""
    context_namespaces=[]
    for each_namespace in component_attributes['environments']:
      if each_namespace['name']=='dev':
        dev_namespace=each_namespace['namespace']
      else:
        context_namespaces.append(each_namespace['namespace'])
    print(f'component_circleci_project_k8s_namespace={dev_namespace}') 
    print(f'component_circleci_context_k8s_namespaces={context_namespaces}')
else:
    print("not found dude")
    

