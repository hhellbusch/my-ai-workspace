#!/usr/bin/env bash
# Idempotent Cluster Link reconcile — Pattern B example.
#
# Reads a ClusterLinkDesired YAML (see desired/*.example.yaml) and applies via
# Confluent Admin REST. Validate field mapping against your CP/CFK version:
#   https://docs.confluent.io/platform/current/kafka-rest/api.html
#
# Usage:
#   reconcile-link.example.sh --spec desired/dc-a-to-dc-b.yaml [--apply|--check-only|--dry-run]
#
# Environment:
#   KAFKA_REST_URL          Base URL (e.g. https://kafka.confluent.svc:8090)
#   KAFKA_CLUSTER_ID        Destination cluster id (local cluster where link is created)
#   KAFKA_REST_BASIC_AUTH_USER / KAFKA_REST_BASIC_AUTH_PASS  (optional)
#   KAFKA_REST_CA_CERT      Path to CA for curl -k alternative (optional)
#
# Requires: yq, curl, jq

set -euo pipefail

SPEC=""
MODE="apply"

usage() {
  cat <<EOF
Usage: $(basename "$0") --spec <desired.yaml> [--apply|--check-only|--dry-run]

  --apply       Create or update link if spec differs (default)
  --check-only  Exit 0 if link matches spec, 1 if missing or drifted
  --dry-run     Print planned REST calls without contacting Admin REST
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec)
      SPEC="${2:?--spec requires a path}"
      shift 2
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --check-only)
      MODE="check-only"
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n "$SPEC" ]] || { usage >&2; exit 2; }
[[ -f "$SPEC" ]] || { echo "Spec not found: $SPEC" >&2; exit 2; }

for cmd in yq curl jq; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required command: $cmd" >&2; exit 2; }
done

link_name="$(yq -r '.spec.linkName' "$SPEC")"
bootstrap="$(yq -r '.spec.source.bootstrapEndpoint' "$SPEC")"
source_cluster_id="$(yq -r '.spec.source.clusterId // ""' "$SPEC")"
managed_cluster="$(yq -r '.spec.managedOn.clusterId' "$SPEC")"

if [[ -z "$link_name" || "$link_name" == "null" ]]; then
  echo "spec.linkName is required in $SPEC" >&2
  exit 2
fi
if [[ -z "$bootstrap" || "$bootstrap" == "null" ]]; then
  echo "spec.source.bootstrapEndpoint is required (REPLICATION Multus IPs)" >&2
  exit 2
fi
if [[ "$bootstrap" == *".svc"* ]] || [[ "$bootstrap" == *"cluster.local"* ]]; then
  echo "bootstrapEndpoint looks like in-cluster DNS — use REPLICATION Multus IPs" >&2
  exit 2
fi

curl_auth=()
if [[ -n "${KAFKA_REST_BASIC_AUTH_USER:-}" ]]; then
  curl_auth=(-u "${KAFKA_REST_BASIC_AUTH_USER}:${KAFKA_REST_BASIC_AUTH_PASS:-}")
fi
curl_tls=()
if [[ -n "${KAFKA_REST_CA_CERT:-}" ]]; then
  curl_tls=(--cacert "$KAFKA_REST_CA_CERT")
else
  curl_tls=(-k)
fi

rest_base="${KAFKA_REST_URL:-}"
cluster_id="${KAFKA_CLUSTER_ID:-}"

build_payload() {
  jq -n \
    --arg link_name "$link_name" \
    --arg bootstrap "$bootstrap" \
    --arg remote_cluster_id "$source_cluster_id" \
    '{
      metadata: { name: $link_name },
      spec: {
        remote_cluster: {
          bootstrap_servers: $bootstrap,
          cluster_id: (if $remote_cluster_id == "" then null else $remote_cluster_id end)
        }
      }
    }'
}

# NOTE: Exact REST schema varies by CP version — treat this payload as a starting point.
# Map mirrorTopics, tls, and auth from $SPEC into spec before production use.

links_url() {
  [[ -n "$rest_base" && -n "$cluster_id" ]] || return 1
  printf '%s/kafka/v3/clusters/%s/links' "${rest_base%/}" "$cluster_id"
}

link_url() {
  [[ -n "$rest_base" && -n "$cluster_id" ]] || return 1
  printf '%s/kafka/v3/clusters/%s/links/%s' "${rest_base%/}" "$cluster_id" "$link_name"
}

fetch_live_bootstrap() {
  local url
  url="$(link_url)" || return 1
  curl -sfS "${curl_tls[@]}" "${curl_auth[@]}" "$url" \
    | jq -r '.remote_cluster.bootstrap_servers // .spec.remote_cluster.bootstrap_servers // empty' 2>/dev/null || true
}

apply_link() {
  local url payload
  payload="$(build_payload)"

  if [[ "$MODE" == "dry-run" ]]; then
    url="$(links_url 2>/dev/null || echo "${KAFKA_REST_URL:-https://<kafka-rest>}/kafka/v3/clusters/${KAFKA_CLUSTER_ID:-<cluster-id>}/links")"
    echo "DRY-RUN POST $url"
    echo "$payload" | jq .
    return 0
  fi

  url="$(links_url)" || {
    echo "KAFKA_REST_URL and KAFKA_CLUSTER_ID required for --apply" >&2
    exit 2
  }

  local live
  live="$(fetch_live_bootstrap || true)"
  if [[ -n "$live" ]]; then
    if [[ "$live" == "$bootstrap" ]]; then
      echo "Link ${link_name} on ${managed_cluster}: bootstrap matches — no-op"
      return 0
    fi
    echo "Link ${link_name} exists but bootstrap differs:" >&2
    echo "  live:     $live" >&2
    echo "  desired:  $bootstrap" >&2
    echo "Update via Admin REST PATCH for your CP version (not implemented in this example)" >&2
    exit 1
  fi

  echo "Creating link ${link_name} on cluster ${cluster_id} (managedOn=${managed_cluster})"
  curl -sfS "${curl_tls[@]}" "${curl_auth[@]}" \
    -X POST "$url" \
    -H 'Content-Type: application/json' \
    -d "$payload"
  echo
}

check_only() {
  local url live
  url="$(link_url)" || {
    echo "KAFKA_REST_URL and KAFKA_CLUSTER_ID required for --check-only" >&2
    exit 2
  }
  if [[ "$MODE" == "dry-run" ]]; then
    echo "DRY-RUN GET $url"
    exit 0
  fi
  live="$(fetch_live_bootstrap || true)"
  if [[ -z "$live" ]]; then
    echo "DRIFT: link ${link_name} not found or unreachable" >&2
    exit 1
  fi
  if [[ "$live" != "$bootstrap" ]]; then
    echo "DRIFT: bootstrap mismatch" >&2
    echo "  live:     $live" >&2
    echo "  desired:  $bootstrap" >&2
    exit 1
  fi
  echo "OK: link ${link_name} matches desired bootstrap"
}

echo "reconcile-link: mode=${MODE} link=${link_name} managedOn=${managed_cluster}"

case "$MODE" in
  check-only) check_only ;;
  apply|dry-run) apply_link ;;
  *) echo "Unknown mode: $MODE" >&2; exit 2 ;;
esac
