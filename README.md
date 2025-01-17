# hmpps-github-actions-runner
This project builds and deploys self-hosted Github Runners to the MinistryOfJustice github organisation. It's deployed to Cloud Platforms, using Helm.

For teams wishing to **use these runners in your own pipelines**, the documentation is [here](https://tech-docs.hmpps.service.justice.gov.uk/sre-internal-docs/).

# Building and Deploying

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

Note: the runner group needs to be be configured manually prior to deployment. The runner group can be configured to limit access to the runners, e.g. so only selected repositories can use them.

### Updating the Actions Runner version

Github requires that the Github Actions Runners versions are kept up-to-date; if an old version is deployed, there is a good chance it will be unable to register because it's too old.

```
ACTIONS_RUNNER_VERSION="2.321.0" \
ACTIONS_RUNNER_PKG_SHA="ba46ba7ce3a4d7236b16fbe44419fb453bc08f866b24f04d549ec89f1722a29e"
```
Use the latest version of the runner and SHA from the [Github Actions Runner releases page](https://github.com/actions/runner/releases) - the checksum will be the one corresponding to `actions-runner-linux-x64`
