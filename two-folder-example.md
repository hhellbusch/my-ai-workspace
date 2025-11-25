# Two-Folder ArgoCD Setup

This example shows how to scan two different folders and pass them as separate variables to Helm.

## Directory Structure

```
your-repo/
├── apps/                          # Application workloads
│   ├── frontend/
│   ├── backend/
│   └── api/
├── infrastructure/                # Infrastructure components
│   ├── monitoring/
│   ├── logging/
│   └── networking/
└── charts/
    └── argocd-apps/
```

## How It Works

### 1. GitHub Action scans both folders

```bash
# Scan apps/ folder
APP_DIRS=$(find ./apps -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec basename {} \; | sort)
APP_ARRAY=$(echo "$APP_DIRS" | jq -R -s -c 'split("\n") | map(select(length > 0))')

# Scan infrastructure/ folder
INFRA_DIRS=$(find ./infrastructure -mindepth 1 -maxdepth 1 -type d -not -path '*/\.*' -exec basename {} \; | sort)
INFRA_ARRAY=$(echo "$INFRA_DIRS" | jq -R -s -c 'split("\n") | map(select(length > 0))')
```

### 2. Pass both variables to Helm

```bash
helm template argocd-apps ./charts/argocd-apps \
  --set-json "applications=$APP_ARRAY" \
  --set-json "infrastructure=$INFRA_ARRAY" \
  | oc apply -f -
```

### 3. Helm generates different ArgoCD Applications

**For applications** (`apps/` folder):
- Name: `frontend`, `backend`, `api`
- Label: `type: application`
- Source path: `apps/frontend`, `apps/backend`, etc.

**For infrastructure** (`infrastructure/` folder):
- Name: `infra-monitoring`, `infra-logging`, `infra-networking`
- Label: `type: infrastructure`
- Source path: `infrastructure/monitoring`, `infrastructure/logging`, etc.

## Example Output

Given this structure:
```
apps/
  ├── frontend/
  └── backend/
infrastructure/
  └── monitoring/
```

The workflow will discover:
```
APP_DIRECTORIES=["frontend","backend"]
INFRA_DIRECTORIES=["monitoring"]
```

And generate 3 ArgoCD Applications:
1. `frontend` (from apps/frontend/)
2. `backend` (from apps/backend/)
3. `infra-monitoring` (from infrastructure/monitoring/)

## Customization

### Different Naming Convention

Edit `charts/argocd-apps/templates/app-of-apps.yaml`:

```yaml
# Change infrastructure app names
name: infra-{{ . }}          # Current: infra-monitoring
# to
name: {{ . }}-infrastructure  # New: monitoring-infrastructure
```

### Different Sync Policies

You can apply different sync policies for each type:

```yaml
# Applications - auto sync
{{- range .Values.applications }}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
{{- end }}

# Infrastructure - manual sync for safety
{{- range .Values.infrastructure }}
  syncPolicy:
    automated: null
    syncOptions:
      - CreateNamespace=true
{{- end }}
```

### Deploy to Different Namespaces

```yaml
# Applications go to their own namespace
{{- range .Values.applications }}
  destination:
    namespace: {{ . }}
{{- end }}

# Infrastructure all goes to "infra" namespace
{{- range .Values.infrastructure }}
  destination:
    namespace: infra
{{- end }}
```

## Testing Locally

```bash
# Test the discovery
APP_DIRS=$(find ./apps -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')
INFRA_DIRS=$(find ./infrastructure -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | jq -R -s -c 'split("\n") | map(select(length > 0))')

echo "Applications: $APP_DIRS"
echo "Infrastructure: $INFRA_DIRS"

# Test the Helm template
helm template argocd-apps ./charts/argocd-apps \
  --set-json "applications=$APP_DIRS" \
  --set-json "infrastructure=$INFRA_DIRS"
```

## Use Cases

This pattern is useful when you want to:
- **Separate concerns**: Apps vs infrastructure
- **Different permissions**: Different teams manage different folders
- **Different sync policies**: Auto-sync apps, manual sync infrastructure
- **Different ArgoCD projects**: Apps in `default`, infra in `infrastructure` project
- **Different naming**: Prefix infrastructure apps with `infra-`

