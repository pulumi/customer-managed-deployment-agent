#!/bin/sh

# Set namespace (modify as needed)
NAMESPACE="default"

# Create timestamped logfile with descriptive name
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOGFILE="pulumi_workflow_pods_monitor_${TIMESTAMP}.log"

# Ensure namespace is set
if [ -z "$NAMESPACE" ]; then
  echo "Error: Namespace must be set."
  exit 1
fi

echo "Starting Pulumi workflow pods monitoring. Log file: $LOGFILE"
echo "Monitoring pods in namespace: $NAMESPACE"
echo "Started at: $(date)" > "$LOGFILE"
echo "Target namespace: $NAMESPACE" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Infinite loop to monitor the pod
while true; do
  PODS=$(kubectl get pods -n "$NAMESPACE" -l 'app.kubernetes.io/component=pulumi-workflow' --no-headers -o custom-columns=":metadata.name")
  
  if [ -z "$PODS" ]; then
    echo "$(date): No matching pulumi-workflow pods found" >> "$LOGFILE"
  else
    for pod in $PODS; do
      echo "===============================================" >> "$LOGFILE"
      echo "$(date): Pod information for $pod" >> "$LOGFILE"
      echo "===============================================" >> "$LOGFILE"
      
      echo "--- DESCRIBE OUTPUT ---" >> "$LOGFILE"
      kubectl describe pod "$pod" -n "$NAMESPACE" >> "$LOGFILE" 2>&1
      
      echo "--- LOGS OUTPUT ---" >> "$LOGFILE"
      kubectl logs -n "$NAMESPACE" "$pod" >> "$LOGFILE" 2>&1 || echo "Failed to get logs" >> "$LOGFILE"
      
      echo "" >> "$LOGFILE"
    done
  fi
  
  sleep 60  # Check every minute
done