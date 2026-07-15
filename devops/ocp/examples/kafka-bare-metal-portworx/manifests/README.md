# Manifest variants — rack labeling

Two parallel examples for the same Kafka + Portworx rack-aware layout. **Do not mix** label keys within one cluster.

| Variant | Directory | Rack label key | Site / region key |
|---------|-----------|----------------|-------------------|
| **Well-known topology** (default) | [`zone-region/`](zone-region/) | `topology.kubernetes.io/zone` | `topology.kubernetes.io/region` |
| **Custom domain labels** | [`custom-rack/`](custom-rack/) | `platform.example.com/rack` | `platform.example.com/site` |

Shared across both variants (label key agnostic):

- [`common/`](common/) — Portworx StorageClass, MCP, kernel tuning (identical)

Side-by-side comparison: [LABELING-COMPARISON.md](../LABELING-COMPARISON.md)
