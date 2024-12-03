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

## Fargate Support

To enable Fargate you will need to use `customer-managed-deployment-agent` >= `1.3.7` and add the following to your pulumi code:

```typescript
// Create a Fargate profile
const fargateProfile = new aws.eks.FargateProfile("cmda-fargate-profile", {
    clusterName: cluster.eksCluster.name,
    podExecutionRoleArn: new aws.iam.Role("fargatePodExecutionRole", {
        assumeRolePolicy: aws.iam.assumeRolePolicyForPrincipal({ Service: "eks-fargate-pods.amazonaws.com" }),
    }).arn,
    subnetIds: eksVpc.privateSubnetIds,
    selectors: [{ namespace: <desired namespace>, labels: { "app.kubernetes.io/name": "workflow-runner" } }]
});
```

Additionally, there are two options for choosing your node size:

* `agentNumCpus` - Number of CPU's for the fargate instance
* `agentMemQuantity` - Quantity of memory in Gigabytes for the fargate instance. i.e. 4 = 4Gi

### 📌 Note

[Fargate Instance Reference](https://docs.aws.amazon.com/eks/latest/userguide/fargate-pod-configuration.html)