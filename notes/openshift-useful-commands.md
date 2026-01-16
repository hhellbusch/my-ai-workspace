# OpenShift Useful Commands

## Pod Management

### Delete Pods Not in Running or Completed State

Delete all pods across all namespaces that are not in Running or Succeeded state:

#### Option 1: Most Robust (Recommended)
```bash
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | xargs -n 2 bash -c 'oc delete pod -n $0 $1'
```

#### Option 2: Using awk
```bash
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded | tail -n +2 | awk '{print $1, $2}' | xargs -n 2 bash -c 'oc delete pod -n $0 $1'
```

#### Option 3: Loop (Most Readable)
```bash
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' | while read namespace pod; do oc delete pod -n "$namespace" "$pod"; done
```

#### Preview Before Deleting
```bash
# First, preview what will be deleted:
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded

# Then delete them:
oc get pods --all-namespaces --field-selector=status.phase!=Running,status.phase!=Succeeded -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | xargs -n 2 bash -c 'oc delete pod -n $0 $1'
```

#### For a Specific Namespace
```bash
# Preview
oc get pods -n <namespace> --field-selector=status.phase!=Running,status.phase!=Succeeded

# Delete
oc get pods -n <namespace> --field-selector=status.phase!=Running,status.phase!=Succeeded -o name | xargs -r oc delete -n <namespace>
```

### Pod States Reference

Common Kubernetes/OpenShift pod states:
- **Running**: Pod is running normally
- **Succeeded**: Pod has completed successfully (completed jobs/pods)
- **Pending**: Pod is waiting to be scheduled or for images to be pulled
- **Failed**: Pod has failed
- **Unknown**: State cannot be determined
- **CrashLoopBackOff**: Pod is repeatedly crashing
- **ImagePullBackOff**: Unable to pull the container image
- **ContainerCreating**: Container is being created
- **Terminating**: Pod is being terminated

---

## Additional Useful Commands

### Get All Pods with Custom Columns
```bash
oc get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName
```

### Watch Pods in Real-time
```bash
oc get pods --all-namespaces --watch
```

### Get Pods by Label
```bash
oc get pods -l app=myapp --all-namespaces
```

### Force Delete Stuck Pods
```bash
oc delete pod <pod-name> -n <namespace> --grace-period=0 --force
```

### Get Pod Events
```bash
oc get events -n <namespace> --sort-by='.lastTimestamp' | grep <pod-name>
```

### Get Pod Logs
```bash
# Current logs
oc logs <pod-name> -n <namespace>

# Previous container logs (for crashed pods)
oc logs <pod-name> -n <namespace> --previous

# Follow logs
oc logs -f <pod-name> -n <namespace>

# Logs from specific container in multi-container pod
oc logs <pod-name> -c <container-name> -n <namespace>
```

### Describe Pod for Troubleshooting
```bash
oc describe pod <pod-name> -n <namespace>
```

### Execute Commands in Running Pod
```bash
oc exec -it <pod-name> -n <namespace> -- /bin/bash
```

### Get Resource Usage
```bash
oc adm top pods --all-namespaces
oc adm top nodes
```










