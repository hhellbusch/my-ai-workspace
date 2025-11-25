# ArgoCD App of Apps Architecture Diagram

## High-Level Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Git Repository (main)                        │
│                                                                       │
│  ┌─────────────────┐         ┌──────────────────────────────┐      │
│  │ root-app.yaml   │         │ charts/argocd-apps/          │      │
│  │ (ROOT APP)      │────────▶│  - Chart.yaml                │      │
│  │                 │         │  - values-production.yaml    │      │
│  │ targetRevision: │         │  - templates/                │      │
│  │    main         │         │      └─ app-of-apps.yaml     │      │
│  └─────────────────┘         └──────────────────────────────┘      │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ ArgoCD Deploys
                                      ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ArgoCD Cluster (Kubernetes)                       │
│                                                                       │
│  ┌───────────────────────────────────────────────────────────┐      │
│  │  Root Application (namespace: argocd)                      │      │
│  │  ┌──────────────────────────────────────────────────┐     │      │
│  │  │ Root App Points to main                          │     │      │
│  │  │ Deploys Helm Chart: charts/argocd-apps/         │     │      │
│  │  │ Uses values-production.yaml                      │     │      │
│  │  └──────────────────────────────────────────────────┘     │      │
│  └───────────────────────────────────────────────────────────┘      │
│                                                                       │
│                    Creates Child Applications ▼                      │
│                                                                       │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │  example-app     │  │  another-app     │  │  monitoring      │  │
│  │  namespace:      │  │  namespace:      │  │  namespace:      │  │
│  │   example-app    │  │   another-app    │  │   monitoring     │  │
│  │                  │  │                  │  │                  │  │
│  │  targetRevision: │  │  targetRevision: │  │  targetRevision: │  │
│  │    v1.2.3       │  │    develop      │  │    v2.0.0       │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## Detailed Component Interaction

```
                        ┌─────────────────────┐
                        │   Operator/GitOps   │
                        │   Pipeline          │
                        └──────────┬──────────┘
                                   │
                    1. Deploys     │
                       Root App    │
                                   ▼
                ┌──────────────────────────────────┐
                │  root-app-production.yaml        │
                │                                  │
                │  apiVersion: argoproj.io/v1alpha1│
                │  kind: Application               │
                │  spec:                           │
                │    source:                       │
                │      repoURL: github.com/...     │
                │      targetRevision: main  ◀──── Always main!
                │      path: charts/argocd-apps/   │
                │      helm:                       │
                │        valueFiles:               │
                │          - values-production.yaml│
                └─────────────┬────────────────────┘
                              │
                2. ArgoCD     │
                   reads      │
                              ▼
         ┌────────────────────────────────────────────────┐
         │  values-production.yaml                        │
         │                                                 │
         │  applications:                                 │
         │    - name: example-app                         │
         │      targetRevision: v1.2.3  ◀──── Controlled │
         │      namespace: example-app       by Helm     │
         │      path: apps/example-app       values      │
         │                                                 │
         │    - name: another-app                         │
         │      targetRevision: develop ◀──── Each app   │
         │      namespace: another-app      has own      │
         │      path: apps/another-app      version      │
         └────────────┬───────────────────────────────────┘
                      │
        3. Helm       │
           template   │
                      ▼
    ┌─────────────────────────────────────────────┐
    │  app-of-apps.yaml (Helm Template)           │
    │                                              │
    │  {{- range .Values.applications }}          │
    │  ---                                         │
    │  apiVersion: argoproj.io/v1alpha1           │
    │  kind: Application                          │
    │  metadata:                                   │
    │    name: {{ .name }}                        │
    │  spec:                                       │
    │    source:                                   │
    │      repoURL: {{ $.Values.source.repoURL }} │
    │      targetRevision: {{ .targetRevision }}  │
    │      path: {{ .path }}                      │
    │  {{- end }}                                  │
    └─────────────┬───────────────────────────────┘
                  │
    4. Creates    │
       Child Apps │
                  ▼
    ┌──────────────────────────────────────────────────┐
    │  Child Application Resources                     │
    │  ┌────────────────────────────────────────────┐  │
    │  │ Application: example-app                   │  │
    │  │ - Points to: apps/example-app @ v1.2.3     │  │
    │  │ - Deploys to: example-app namespace        │  │
    │  └────────────────────────────────────────────┘  │
    │  ┌────────────────────────────────────────────┐  │
    │  │ Application: another-app                   │  │
    │  │ - Points to: apps/another-app @ develop    │  │
    │  │ - Deploys to: another-app namespace        │  │
    │  └────────────────────────────────────────────┘  │
    └──────────────────────────────────────────────────┘
```

## Environment Comparison

```
┌──────────────┬─────────────────────┬─────────────────────┬─────────────────────┐
│              │     PRODUCTION      │       STAGING       │     DEVELOPMENT     │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ Root App     │ root-app-           │ root-app-           │ root-app.yaml       │
│              │ production.yaml     │ staging.yaml        │                     │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ Values File  │ values-             │ values-             │ values-             │
│              │ production.yaml     │ staging.yaml        │ development.yaml    │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ Root Target  │ main                │ main                │ main                │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ example-app  │ v1.2.3              │ v1.3.0-rc1          │ develop             │
│ Target       │ (stable tag)        │ (release candidate) │ (latest branch)     │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ another-app  │ v2.1.0              │ develop             │ feature/new-feature │
│ Target       │ (stable tag)        │ (testing)           │ (feature branch)    │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ monitoring   │ v2.0.0              │ v2.1.0-beta         │ develop             │
│ Target       │ (stable)            │ (testing)           │ (latest)            │
├──────────────┼─────────────────────┼─────────────────────┼─────────────────────┤
│ Auto-sync    │ Manual/Automated    │ Automated           │ Automated           │
│              │ (selective)         │ (testing)           │ (rapid iteration)   │
└──────────────┴─────────────────────┴─────────────────────┴─────────────────────┘
```

## Version Update Flow

```
┌───────────────────────────────────────────────────────────────────────┐
│                    Promotion Workflow                                  │
└───────────────────────────────────────────────────────────────────────┘

  Developer          Git Repository              ArgoCD
     │                    │                         │
     │                    │                         │
     ├─1. Push feature──▶│                         │
     │   to branch        │                         │
     │                    │                         │
     │                    │                         │
     ├─2. Update values─▶│                         │
     │   targetRevision:  │                         │
     │   feature/xyz      │                         │
     │   (commit to main) │                         │
     │                    │                         │
     │                    ├─3. Root app detects────▶│
     │                    │    change in values     │
     │                    │    file on main         │
     │                    │                         │
     │                    │                    4. Root app
     │                    │                       syncs Helm
     │                    │                       chart
     │                    │                         │
     │                    │                    5. Child app
     │                    │                       updated with
     │                    │                       new targetRevision
     │                    │                         │
     │                    │                    6. Child app syncs
     │                    │   ◀──────────────────── from feature/xyz
     │                    │                         │
     │                    │                         │
     │◀──7. Verify────────┴─────────────────────────┤
     │    deployment                                │
     │                                               │
```

## Version Control Structure

```
main branch (source of truth)
│
├── root-app.yaml                      ← Points to main
├── root-app-production.yaml           ← Points to main
├── root-app-staging.yaml              ← Points to main
│
├── charts/argocd-apps/
│   ├── values.yaml                    ← Default: defines app versions
│   ├── values-production.yaml         ← Prod: stable versions
│   ├── values-staging.yaml            ← Staging: RC versions
│   └── values-development.yaml        ← Dev: branch versions
│
├── apps/
│   ├── example-app/
│   │   └── deployment.yaml            ← Can be at v1.2.3 tag
│   └── another-app/
│       └── deployment.yaml            ← Can be at develop branch
│
└── infrastructure/
    └── monitoring/
        └── prometheus.yaml            ← Can be at v2.0.0 tag


Branch: v1.2.3 (tag)              Branch: develop           Branch: feature/xyz
       │                                 │                          │
       │                                 │                          │
       └─ Production deploys from        │                          │
          this tag                       └─ Staging deploys         │
                                            from develop            └─ Dev deploys
                                                                       from feature
```

## Sync Behavior Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Auto-Sync Enabled                                │
└─────────────────────────────────────────────────────────────────────┘

User commits change to values-production.yaml on main
                    ↓
        Root app detects out-of-sync
                    ↓
        Root app auto-syncs (pulls from main)
                    ↓
        Helm chart templated with new values
                    ↓
        Child app definition updated
                    ↓
        Child app detects out-of-sync
                    ↓
        Child app auto-syncs from new targetRevision
                    ↓
        Application deployed/updated


┌─────────────────────────────────────────────────────────────────────┐
│                     Manual Sync (Production)                         │
└─────────────────────────────────────────────────────────────────────┘

User commits change to values-production.yaml on main
                    ↓
        Root app detects out-of-sync
                    ↓
        Operator reviews change in UI
                    ↓
        Operator clicks "Sync" button
                    ↓
        Helm chart templated with new values
                    ↓
        Child app definition updated
                    ↓
        Child app auto-syncs from new targetRevision
                    ↓
        Application deployed/updated
```

## Multi-Environment Architecture

```
                    ┌─────────────────────┐
                    │  Git Repository     │
                    │  (main branch)      │
                    └──────────┬──────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
    ┌──────────────┐   ┌──────────────┐  ┌──────────────┐
    │ Production   │   │  Staging     │  │ Development  │
    │ Cluster      │   │  Cluster     │  │ Cluster      │
    └──────────────┘   └──────────────┘  └──────────────┘
    │                  │                  │
    │ Root App:        │ Root App:        │ Root App:
    │ ├─ main         │ ├─ main         │ ├─ main
    │ └─ values-prod   │ └─ values-stg   │ └─ values-dev
    │                  │                  │
    │ Apps:            │ Apps:            │ Apps:
    │ ├─ app-1: v1.2.3 │ ├─ app-1: v1.3.0 │ ├─ app-1: develop
    │ ├─ app-2: v2.1.0 │ ├─ app-2: develop│ ├─ app-2: feature/x
    │ └─ app-3: v1.0.0 │ └─ app-3: v1.1.0 │ └─ app-3: develop
    └──────────────────┘ └──────────────────┘ └──────────────────┘
```

## Key Principles Illustrated

1. **Single Source of Truth**: All root apps point to `main` branch
2. **Centralized Control**: All app versions defined in values files on `main`
3. **Environment Flexibility**: Different environments deploy different versions
4. **GitOps Workflow**: All changes tracked in Git history
5. **Separation of Concerns**: Root app config separate from app versions
6. **Declarative**: Desired state defined in values files

## Benefits Visualization

```
Traditional Approach              App of Apps Pattern
─────────────────────            ──────────────────────

Manual kubectl apply    ────▶    GitOps via ArgoCD
Multiple repos          ────▶    Single repo
Version scattered       ────▶    Centralized in values
Hard to audit          ────▶    Full Git history
Environment drift      ────▶    Consistent state
Manual rollback        ────▶    Git revert
Hard to promote        ────▶    Update values file
```

