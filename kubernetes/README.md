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

## Performance

### AWS

To optimize the performance of your deployments, you can use a pull-through cache in Amazon Elastic Container Registry (ECR). This allows you to cache frequently used images closer to your Kubernetes cluster, reducing the time it takes to pull images, and to prevent rate limiting.

For more information and an example of how to set up a pull-through cache in ECR using Pulumi, refer to the following:

* [Pulumi ECR Cache Example](https://github.com/pulumi/examples/tree/master/aws-ts-ecr-cache).
* [Implementing AWS ECR Pull Through cache for EKS cluster- most in-depth implementation details](https://marcincuber.medium.com/implementing-aws-ecr-pull-through-cache-for-eks-cluster-most-in-depth-implementation-details-e51395568034)

## Troubleshooting

If you encounter issues with the deployment agent, please refer to our [troubleshooting guide](./troubleshooting/README.md) which includes:

* Diagnostic steps for identifying and resolving common problems
* Monitoring scripts to track pod status and resource usage
* Instructions for creating debug pods
* Example Kyverno policies for controlling pod scheduling
