import * as pulumi from "@pulumi/pulumi";
import * as kubernetes from "@pulumi/kubernetes";

export interface PulumiSelfHostedAgentComponentArgs {
    namespace: kubernetes.core.v1.Namespace;
    imageName: pulumi.Input<string>;
    imagePullPolicy: pulumi.Input<string>;
    agentReplicas: pulumi.Input<number>;
    selfHostedAgentsAccessToken: pulumi.Input<string>;
    selfHostedServiceURL: pulumi.Input<string>;
}

export class PulumiSelfHostedAgentComponent extends pulumi.ComponentResource {
    public readonly agentDeployment: kubernetes.apps.v1.Deployment;
    public readonly agentServiceAccount: kubernetes.core.v1.ServiceAccount;
    public readonly agentRole: kubernetes.rbac.v1.Role;
    public readonly agentRoleBinding: kubernetes.rbac.v1.RoleBinding;

    labels = {
        "app.kubernetes.io/name": "customer-managed-deployment-agent",
    };

    constructor(name: string, args: PulumiSelfHostedAgentComponentArgs, opts?: pulumi.ComponentResourceOptions) {
        super("pulumi-service:kubernetes:PulumiSelfHostedAgentComponent", name, args, opts);

        const agentConfig = new kubernetes.core.v1.ConfigMap("agent-config", {
            metadata: {
                name: "agent-config",
                namespace: args.namespace.metadata.name,
                labels: this.labels,
            },
            data: {
                "PULUMI_AGENT_SERVICE_URL": args.selfHostedServiceURL,
                "PULUMI_AGENT_IMAGE": args.imageName,
                "PULUMI_AGENT_IMAGE_PULL_POLICY": args.imagePullPolicy,
            },
        }, {parent: this});

        const agentSecret = new kubernetes.core.v1.Secret("agent-secret", {
            metadata: {
                name: "agent-secret",
                namespace: args.namespace.metadata.name,
            },
            stringData: {
                "PULUMI_AGENT_TOKEN": args.selfHostedAgentsAccessToken,
            }
        }, {parent: this});

        this.agentServiceAccount = new kubernetes.core.v1.ServiceAccount("deployment-agent", {
            metadata: {
                namespace: args.namespace.metadata.name,
                labels: this.labels,
            },
        }, {parent: this});

        this.agentRole = new kubernetes.rbac.v1.Role("deployment-agent", {
            metadata: {
                namespace: args.namespace.metadata.name,
                labels: this.labels,
            },
            rules: [
                {
                    apiGroups: [""],
                    resources: ["pods", "pods/log", "configmaps"],
                    verbs: ["create", "get", "list", "watch", "update", "delete"],
                },
            ],
        }, {parent: this});

        this.agentRoleBinding = new kubernetes.rbac.v1.RoleBinding("deployment-agent", {
            metadata: {
                namespace: args.namespace.metadata.name,
                labels: this.labels,
            },
            subjects: [
                {
                    kind: "ServiceAccount",
                    name: this.agentServiceAccount.metadata.name,
                    namespace: args.namespace.metadata.namespace,
                },
            ],
            roleRef: {
                kind: "Role",
                name: this.agentRole.metadata.name,
                apiGroup: "rbac.authorization.k8s.io"
            }
        }, {parent: this});

        this.agentDeployment = new kubernetes.apps.v1.Deployment("deployment-agent-pool", {
            metadata: {
                name: "deployment-agent-pool",
                namespace: args.namespace.metadata.name,
                annotations: {
                    "app.kubernetes.io/name": "pulumi-deployment-agent-pool",
                },
                labels: this.labels,
            },
            spec: {
                replicas: args.agentReplicas,
                selector: {
                    matchLabels: this.labels,
                },
                template: {
                    metadata: {
                        labels: this.labels,
                    },
                    spec: {
                        serviceAccountName: this.agentServiceAccount.metadata.name,
                        containers: [
                            {
                                name: "agent",
                                image: args.imageName,
                                imagePullPolicy: args.imagePullPolicy,
                                env: [
                                    {
                                        name: "PULUMI_AGENT_DEPLOY_TARGET",
                                        value: "kubernetes",
                                    },
                                    {
                                        name: "PULUMI_AGENT_SHARED_VOLUME_DIRECTORY",
                                        value: "/mnt/work",
                                    },
                                    {
                                        name: "PULUMI_AGENT_SERVICE_URL",
                                        valueFrom: {
                                            configMapKeyRef: {
                                                name: agentConfig.metadata.name,
                                                key: "PULUMI_AGENT_SERVICE_URL",
                                            },
                                        },
                                    },
                                    {
                                        name: "PULUMI_AGENT_IMAGE",
                                        valueFrom: {
                                            configMapKeyRef: {
                                                name: agentConfig.metadata.name,
                                                key: "PULUMI_AGENT_IMAGE",
                                            },
                                        },
                                    },
                                    {
                                        name: "PULUMI_AGENT_IMAGE_PULL_POLICY",
                                        valueFrom: {
                                            configMapKeyRef: {
                                                name: agentConfig.metadata.name,
                                                key: "PULUMI_AGENT_IMAGE_PULL_POLICY",
                                            },
                                        },
                                    },
                                    {
                                        name: "PULUMI_AGENT_TOKEN",
                                        valueFrom: {
                                            secretKeyRef: {
                                                name: agentSecret.metadata.name,
                                                key: "PULUMI_AGENT_TOKEN",
                                            },
                                        },
                                    },
                                ],
                                volumeMounts: [
                                    {
                                        name: "agent-work",
                                        mountPath: "/mnt/work",
                                    },
                                ],
                            },
                        ],
                        volumes: [
                            {
                                name: "agent-work",
                                emptyDir: {},
                            },
                            {
                                name: "agent-config",
                                configMap: {
                                    name: agentConfig.metadata.name,
                                }
                            },
                        ],
                    },
                },
            },
        }, {parent: this});

        this.registerOutputs();
    }
}
