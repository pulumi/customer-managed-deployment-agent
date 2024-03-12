import * as pulumi from "@pulumi/pulumi";
import * as k8s from "@pulumi/kubernetes";
import { PulumiSelfHostedAgentComponent } from "./agent";

const pulumiConfig = new pulumi.Config();
export const ns = new k8s.core.v1.Namespace("stack-namespace", {
    metadata: { name: pulumiConfig.require("agentNamespace") },
});

const agent = new PulumiSelfHostedAgentComponent(
    "self-hosted-agent",
    {
        namespace: ns,
        imageName: pulumiConfig.require("agentImage"),
        selfHostedAgentsAccessToken: pulumiConfig.requireSecret("selfHostedAgentsAccessToken"),
    },
    { dependsOn: [ns] },
);