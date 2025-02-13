// Function to create and serialize a Pod
import { V1Pod } from "@kubernetes/client-node";

export function createSerializedPod(): string {
    const pod: V1Pod = {
        apiVersion: "v1",
        kind: "Pod",
        metadata: {
            name: "example-pod",
            namespace: "default",
            labels: {
                app: "example",
            },
        },
        spec: {
            serviceAccountName: "example-service-account",
            restartPolicy: "Never",
            imagePullSecrets: [{ name: "example-image-pull-secret" }],
            initContainers: [
                {
                    name: "copy-workflow-runner",
                    image: "agent-image:latest",
                    imagePullPolicy: "IfNotPresent",
                    command: ["cp", "/usr/local/bin/workflow-runner", "/mnt/pulumi/workflow/workflow-runner"],
                    volumeMounts: [
                        {
                            name: "workflow-runner-volume",
                            mountPath: "/mnt/pulumi/workflow",
                        },
                    ],
                },
            ],
            containers: [
                {
                    name: "pulumi-workflow",
                    image: "worker-image:latest",
                    command: [
                        "/mnt/pulumi/workflow/workflow-runner",
                        "run",
                        "https://example-service-url",
                        "example-job-id",
                        "example-job-token",
                        "/mnt/pulumi/workflow/job.json",
                        "example-oidc-token",
                    ],
                    resources: {
                        requests: {
                            cpu: "100m",
                            memory: "256Mi",
                        },
                    },
                    volumeMounts: [
                        {
                            name: "workflow-runner-volume",
                            mountPath: "/mnt/pulumi/workflow",
                        },
                        {
                            name: "cm-volume",
                            mountPath: "/mnt/pulumi/workflow/job.json",
                            subPath: "job.json",
                        },
                    ],
                },
            ],
            volumes: [
                {
                    name: "workflow-runner-volume",
                    emptyDir: {},
                },
                {
                    name: "cm-volume",
                    configMap: {
                        name: "workflow-cm",
                    },
                },
            ],
        },
    };

    // Serialize the Pod object to JSON
    return JSON.stringify(pod, null, 2);
}