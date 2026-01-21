# Database Secret Management with RHACM

Complete workflow for managing database credentials across environments using RHACM and External Secrets Operator.

## Overview

This example demonstrates enterprise-grade database credential management:

1. **External Storage** - Credentials stored in Vault/AWS Secrets Manager
2. **Environment Separation** - Different credentials per environment (dev/staging/prod)
3. **Automatic Rotation** - Credentials refresh automatically
4. **Connection Templates** - Generate connection strings from components
5. **Application Integration** - Mount as environment variables or files

## Use Cases

- **PostgreSQL Credentials** - Username, password, connection strings
- **MySQL/MariaDB Access** - Multi-environment database access
- **MongoDB Authentication** - Replica set connection strings
- **Redis Cache Credentials** - Password and connection details
- **Multi-Database Applications** - Apps connecting to multiple databases

## Architecture

```
┌──────────────────────────────────────────┐
│      External Secret Store               │
│      (Vault / AWS SM / Azure KV)         │
│                                          │
│  /database/prod                          │
│  /database/staging                       │
│  /database/dev                           │
└───────────┬──────────────────────────────┘
            │
            │ External Secrets Operator syncs
            │
┌───────────▼──────────────────────────────┐
│      Managed Cluster(s)                  │
│                                          │
│  ExternalSecret → Kubernetes Secret      │
│         ↓                                │
│  Pod mounts secret as:                   │
│  - Environment variables                 │
│  - Volume mount                          │
└──────────────────────────────────────────┘
```

## Prerequisites

- External Secrets Operator installed (see Example 3)
- SecretStore configured (Vault, AWS SM, etc.)
- Database credentials stored in external store
- Target namespaces created

## Quick Start

### 1. Store Credentials in External Store

**Vault Example:**
```bash
# Store production database credentials
vault kv put secret/database/production \
  username=app_prod_user \
  password=SecureP@ssw0rd123 \
  host=postgres-prod.example.com \
  port=5432 \
  database=myapp_production \
  sslmode=require

# Store staging credentials
vault kv put secret/database/staging \
  username=app_staging_user \
  password=StagingPass456 \
  host=postgres-staging.example.com \
  port=5432 \
  database=myapp_staging \
  sslmode=prefer
```

**AWS Secrets Manager Example:**
```bash
# Production database
aws secretsmanager create-secret \
  --name prod/database/myapp \
  --secret-string '{
    "username": "app_prod_user",
    "password": "SecureP@ssw0rd123",
    "host": "postgres-prod.amazonaws.com",
    "port": "5432",
    "database": "myapp_production"
  }' \
  --region us-east-1

# Staging database
aws secretsmanager create-secret \
  --name staging/database/myapp \
  --secret-string '{
    "username": "app_staging_user",
    "password": "StagingPass456",
    "host": "postgres-staging.amazonaws.com",
    "port": "5432",
    "database": "myapp_staging"
  }' \
  --region us-east-1
```

### 2. Apply RHACM Policies

```bash
# Apply ExternalSecret policy for production
oc apply -f postgresql-externalsecret-policy.yaml
oc apply -f placement-production.yaml
oc apply -f placement-binding.yaml
```

### 3. Verify Secret Creation

```bash
# Check on managed cluster
oc --context=prod-cluster get externalsecret -n my-app
oc --context=prod-cluster get secret database-credentials -n my-app

# View generated connection string
oc --context=prod-cluster get secret database-credentials -n my-app \
  -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

## Example Configurations

### Example 1: PostgreSQL with Connection String

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: postgresql-database-secret
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: create-postgresql-externalsecret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: ExternalSecret
            metadata:
              name: postgresql-credentials
              namespace: production-apps
            spec:
              refreshInterval: 1h
              secretStoreRef:
                name: vault-backend
                kind: SecretStore
              target:
                name: database-credentials
                creationPolicy: Owner
                template:
                  engineVersion: v2
                  type: Opaque
                  data:
                    # Individual fields
                    DB_USERNAME: "{{ .username }}"
                    DB_PASSWORD: "{{ .password }}"
                    DB_HOST: "{{ .host }}"
                    DB_PORT: "{{ .port }}"
                    DB_NAME: "{{ .database }}"
                    DB_SSLMODE: "{{ .sslmode }}"
                    
                    # PostgreSQL connection URL
                    DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .database }}?sslmode={{ .sslmode }}"
                    
                    # Alternative: postgres:// format
                    POSTGRES_URL: "postgres://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .database }}"
              data:
              - secretKey: username
                remoteRef:
                  key: database/production
                  property: username
              - secretKey: password
                remoteRef:
                  key: database/production
                  property: password
              - secretKey: host
                remoteRef:
                  key: database/production
                  property: host
              - secretKey: port
                remoteRef:
                  key: database/production
                  property: port
              - secretKey: database
                remoteRef:
                  key: database/production
                  property: database
              - secretKey: sslmode
                remoteRef:
                  key: database/production
                  property: sslmode
```

### Example 2: MySQL with Multi-Environment

```yaml
apiVersion: policy.open-cluster-management.io/v1
kind: Policy
metadata:
  name: mysql-database-secrets
  namespace: rhacm-policies
spec:
  remediationAction: enforce
  disabled: false
  policy-templates:
  # Production environment
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: mysql-production-secret
      spec:
        remediationAction: enforce
        severity: high
        namespaceSelector:
          include:
          - production-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: ExternalSecret
            metadata:
              name: mysql-credentials
              namespace: production-apps
            spec:
              refreshInterval: 30m
              secretStoreRef:
                name: vault-backend
                kind: SecretStore
              target:
                name: mysql-credentials
                creationPolicy: Owner
                template:
                  type: Opaque
                  data:
                    MYSQL_USER: "{{ .username }}"
                    MYSQL_PASSWORD: "{{ .password }}"
                    MYSQL_HOST: "{{ .host }}"
                    MYSQL_PORT: "{{ .port }}"
                    MYSQL_DATABASE: "{{ .database }}"
                    # MySQL connection string
                    MYSQL_URL: "mysql://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .database }}"
              dataFrom:
              - extract:
                  key: mysql/production
  
  # Staging environment
  - objectDefinition:
      apiVersion: policy.open-cluster-management.io/v1
      kind: ConfigurationPolicy
      metadata:
        name: mysql-staging-secret
      spec:
        remediationAction: enforce
        severity: medium
        namespaceSelector:
          include:
          - staging-apps
        object-templates:
        - complianceType: musthave
          objectDefinition:
            apiVersion: external-secrets.io/v1beta1
            kind: ExternalSecret
            metadata:
              name: mysql-credentials
              namespace: staging-apps
            spec:
              refreshInterval: 30m
              secretStoreRef:
                name: vault-backend
                kind: SecretStore
              target:
                name: mysql-credentials
                creationPolicy: Owner
              dataFrom:
              - extract:
                  key: mysql/staging
```

### Example 3: MongoDB Replica Set

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: mongodb-credentials
  namespace: production-apps
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: mongodb-credentials
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        MONGO_USERNAME: "{{ .username }}"
        MONGO_PASSWORD: "{{ .password }}"
        MONGO_DATABASE: "{{ .database }}"
        # MongoDB replica set connection string
        MONGO_URL: "mongodb://{{ .username }}:{{ .password }}@{{ .replica1 }}:27017,{{ .replica2 }}:27017,{{ .replica3 }}:27017/{{ .database }}?replicaSet={{ .replicaset }}&authSource=admin"
  data:
  - secretKey: username
    remoteRef:
      key: mongodb/production
      property: username
  - secretKey: password
    remoteRef:
      key: mongodb/production
      property: password
  - secretKey: database
    remoteRef:
      key: mongodb/production
      property: database
  - secretKey: replica1
    remoteRef:
      key: mongodb/production
      property: replica1
  - secretKey: replica2
    remoteRef:
      key: mongodb/production
      property: replica2
  - secretKey: replica3
    remoteRef:
      key: mongodb/production
      property: replica3
  - secretKey: replicaset
    remoteRef:
      key: mongodb/production
      property: replicaset
```

### Example 4: Redis with TLS

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: redis-credentials
  namespace: production-apps
spec:
  refreshInterval: 15m
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: redis-credentials
    creationPolicy: Owner
    template:
      type: Opaque
      data:
        REDIS_PASSWORD: "{{ .password }}"
        REDIS_HOST: "{{ .host }}"
        REDIS_PORT: "{{ .port }}"
        # Redis connection URLs
        REDIS_URL: "redis://:{{ .password }}@{{ .host }}:{{ .port }}/0"
        REDIS_TLS_URL: "rediss://:{{ .password }}@{{ .host }}:{{ .port }}/0"
  dataFrom:
  - extract:
      key: redis/production
```

## Application Integration

### Method 1: Environment Variables

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production-apps
spec:
  template:
    spec:
      containers:
      - name: app
        image: my-app:latest
        envFrom:
        # Load all secret keys as environment variables
        - secretRef:
            name: database-credentials
        # Or specify individual keys
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: DATABASE_URL
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: database-credentials
              key: DB_PASSWORD
```

### Method 2: Volume Mount

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production-apps
spec:
  template:
    spec:
      containers:
      - name: app
        image: my-app:latest
        volumeMounts:
        - name: db-credentials
          mountPath: /etc/secrets/database
          readOnly: true
      volumes:
      - name: db-credentials
        secret:
          secretName: database-credentials
          items:
          - key: DATABASE_URL
            path: connection-string
          - key: DB_PASSWORD
            path: password
```

Application reads from `/etc/secrets/database/connection-string`.

### Method 3: Init Container

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
  namespace: production-apps
spec:
  template:
    spec:
      initContainers:
      - name: wait-for-db
        image: postgres:15
        command:
        - sh
        - -c
        - |
          until pg_isready -h $DB_HOST -U $DB_USERNAME; do
            echo "Waiting for database..."
            sleep 2
          done
        envFrom:
        - secretRef:
            name: database-credentials
      containers:
      - name: app
        image: my-app:latest
        envFrom:
        - secretRef:
            name: database-credentials
```

## Security Best Practices

### 1. Least Privilege Database Users

Create application-specific database users:

```sql
-- Production read-write user
CREATE USER app_prod_user WITH PASSWORD 'SecureP@ssw0rd123';
GRANT CONNECT ON DATABASE myapp_production TO app_prod_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_prod_user;

-- Read-only reporting user
CREATE USER app_readonly_user WITH PASSWORD 'ReadOnlyPass456';
GRANT CONNECT ON DATABASE myapp_production TO app_readonly_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly_user;
```

### 2. Connection Pooling

Use connection pooling to limit database connections:

```yaml
# In secret template
PGBOUNCER_URL: "postgresql://{{ .username }}:{{ .password }}@pgbouncer:6432/{{ .database }}"
MAX_CONNECTIONS: "20"
MIN_CONNECTIONS: "5"
CONNECTION_TIMEOUT: "30"
```

### 3. SSL/TLS Enforcement

Always use encrypted connections:

```yaml
# PostgreSQL
DATABASE_URL: "postgresql://...?sslmode=require"

# MySQL
MYSQL_URL: "mysql://...?tls=true"

# MongoDB
MONGO_URL: "mongodb://...?ssl=true"
```

### 4. Credential Rotation

```yaml
spec:
  refreshInterval: 1h  # Sync every hour
  # ESO will detect changes in external store and update secret
```

For automatic rotation, use Vault dynamic secrets or AWS RDS IAM authentication.

## Troubleshooting

### Connection Failures

```bash
# Test connection from pod
oc run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql "$DATABASE_URL"

# Check DNS resolution
oc run -it --rm debug --image=busybox --restart=Never -- \
  nslookup postgres-prod.example.com

# Verify secret values
oc get secret database-credentials -o yaml
oc get secret database-credentials -o jsonpath='{.data.DATABASE_URL}' | base64 -d
```

### ExternalSecret Not Syncing

```bash
# Check ExternalSecret status
oc describe externalsecret postgresql-credentials -n production-apps

# Check ESO logs
oc logs -n openshift-operators -l app.kubernetes.io/name=external-secrets -f

# Verify SecretStore connectivity
oc get secretstore vault-backend -n production-apps -o yaml
```

### Wrong Credentials

```bash
# Check source in external store
vault kv get secret/database/production

# Force refresh
oc annotate externalsecret postgresql-credentials \
  force-sync="$(date +%s)" -n production-apps
```

## Dynamic Secrets (Vault)

For maximum security, use Vault dynamic database secrets:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: dynamic-db-credentials
  namespace: production-apps
spec:
  refreshInterval: 5m  # Short-lived credentials
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
    template:
      data:
        DATABASE_URL: "postgresql://{{ .username }}:{{ .password }}@postgres:5432/myapp"
  data:
  - secretKey: username
    remoteRef:
      key: database/creds/my-role  # Vault dynamic secret path
      property: username
  - secretKey: password
    remoteRef:
      key: database/creds/my-role
      property: password
```

Vault generates temporary credentials with TTL.

## Next Steps

- [Example 6: Advanced Patterns](../6_advanced_patterns/) - Complex scenarios and best practices
- [Example 3: External Secrets Operator](../3_external_secrets_operator/) - ESO setup and configuration

## References

- [PostgreSQL Connection Strings](https://www.postgresql.org/docs/current/libpq-connect.html#LIBPQ-CONNSTRING)
- [MySQL Connection Parameters](https://dev.mysql.com/doc/refman/8.0/en/connecting.html)
- [MongoDB Connection String](https://www.mongodb.com/docs/manual/reference/connection-string/)
- [Vault Database Secrets Engine](https://developer.hashicorp.com/vault/docs/secrets/databases)

