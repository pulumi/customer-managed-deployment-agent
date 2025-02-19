# Troubleshooting

## Steps

The order of troubleshooting should be something like this, the pods you are looking for is pulumi-workflow-runner-* the agent pool has a log but a lot of it is just it kicking off the runner, but that may be useful also.
kubectl events -n namespace in one window
kubectl describe pod -n namespace podname in another windows
once its started: kubectl logs -n namespace podname
I would set the deployment down to 1 worker until you get this all working. It makes it harder to troubleshoot trying to figure out what agent is kicking off what runner.
Hopefully they can get the MutatingWebhook in and the pods on the right nodes as that will eliminate one factor

## Scripts

### pod_monitoring.sh

```bash
# Monitor pods with a specific label
./pod_monitoring.sh -n my-namespace -s "app=myapp" -i 30

# Monitor pods matching a name pattern
./pod_monitoring.sh -n my-namespace -p "web-.*" -t 7200

# Monitor until specific status
./pod_monitoring.sh -n my-namespace -s "job-name=backup" -c "Succeeded,Failed"
```

### pod_workflow_pods_monitor.sh

```bash
./pulumi_workflow_pods_monitor.sh -n pulumi-agent-pool -i 30 -m 5 -d /var/log/monitoring
```
