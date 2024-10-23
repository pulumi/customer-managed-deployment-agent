# Installing the self-managed agent into Kubernetes

## Prerequisites

* Use `pulumi config` to set imageName, namespace, and access token

* Install

```bash
pulumi config set agentNamespace <desired namespace>
pulumi config set --secret selfHostedAgentsAccessToken <access token>
pulumi config set agentImage <imageTag>
pulumi config set agentReplicas <replicas>

pulumi up
```

For example:

```bash
pulumi config set agentNamespace cmda
pulumi config set --secret selfHostedAgentsAccessToken pul-...
pulumi config set agentImage pulumi/customer-managed-deployment-agent:latest-amd64
pulumi config set agentReplicas 3
```

Optionally you can set an `agentImagePullPolicy` to a [Kubernetes supported value](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy), which defaults to `Always`.

## workerServiceAccount

There is a ServiceAccount(`workerServiceAccount`) in the `index.ts` can be configured to support cloud service accounts.

This folder also contains a [raw kubernetes yaml file](./raw_deployment.yaml) for reference.
