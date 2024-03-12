# Installing the self managed agent into Kubernetes

## Prerequisites 

* Build container and push to docker repository [Dockerfile](../Dockerfile)
* Use `pulumi config` to set imageName, namespace, and access token

* Install
```bash
pulumi config set agentNamespace <desired namespace>
pulumi config set --secret pulumi-agent-kubernetes:selfHostedAgentsAccessToken <access token>
pulumi config set agentImage <imageTag>

pulumi up
```

This folder also contains a [raw kubernetes yaml file](./raw_deployment.yaml) for reference.