# hmpps-github-actions-runner
This deploys a github runner to a repository

Needs a bunch of secrets:

### Repo secrets

- GHCR_TOKEN - an app token that is used to build the image
- KUBE_CERT - certificate for Kubernetes (can be found base64 encoded in ~/.kube/config)
- KUBE_CLUSTER - Kubernetes cluster (found in ~/.kube/config)
- KUBE_NAMESPACE - The namespace to which this runner will belong
- KUBE_SERVER - the AWS eks instance on which the Kubernetes cluster is running (API endpoint)
- KUBE_TOKEN - a token to gain access to the Kubernetes cluster. It's the long one.

Note: The Kubernetes environmet variables can be populated as part of the bootstrap process (I think?)

### Kubernetes namespace secrets

- GITHUB_REPOSITORY - this is the repo to which the runner should be registered
- GITHUB_TOKEN - this is the token to authenticate to the repo to which the runner will be attached

