# hmpps-github-actions-runner
This deploys a self-hosted Github Runner to the github organisation.

Documentation about it is [here](https://tech-docs.hmpps.service.justice.gov.uk/sreinternaldocs) 

It's deployed to Cloud Platforms, using Helm.

## Secrets/variables required:

### Repo secrets

- GH_PRIVATE_KEY - A private key for a Github App that has rights to create runners in the destination repository

### Environment secrets (populated by Cloud Platforms terraform)

- KUBE_CERT - certificate for Kubernetes (can be found base64 encoded in ~/.kube/config)
- KUBE_CLUSTER - Kubernetes cluster (found in ~/.kube/config)
- KUBE_NAMESPACE - the namespace to which this runner will belong
- KUBE_SERVER - the AWS eks instance on which the Kubernetes cluster is running (API endpoint)
- KUBE_TOKEN - a token to gain access to the Kubernetes cluster. It's the long one.

### Repo environment variables

- GH_APP_ID - the corresponding AppId for the Github App
- RUNNER_LABEL - the label by which the runner is invoked
- RUNNER_GROUP - the runner group to assign the new runners to.
