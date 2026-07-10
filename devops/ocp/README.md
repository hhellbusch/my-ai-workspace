---
review:
  status: unreviewed
  notes: "Review block backfilled 2026-07-22. Content predates explicit review metadata."
description: OpenShift troubleshooting, configuration examples, and quick references
---

# OpenShift

20+ troubleshooting guides: API slowness, bare metal, CSR management, namespace termination, OVN-Kubernetes. SNO lab setup, [dynamic storage](examples/sno-kvm-lab/dynamic-storage.md), [image registry](examples/sno-kvm-lab/image-registry-sno-lab.md), [local storage bootstrap](examples/sno-kvm-lab/local-storage.md).

- [VLAN Network Segmentation](vlan-network-segmentation.md) — What install-config VLANs become on the cluster, day-2 VLAN management via Multus/NAD
- [Disconnected install (Quay + oc-mirror)](disconnected-install/) — mirror-registry, oc-mirror v2, ImageSet examples, phased working guide
- [IBM Z / LinuxONE](ibm-z/) — s390x vocabulary, CIM ABI LPAR, AOP fork notes, ACM vs Metal3 ([index](ibm-z/README.md))
- [Examples](examples/) — Configuration examples and templates ([Kafka + Portworx rack-aware](examples/kafka-bare-metal-portworx/README.md))
- [Notes](notes/) — Informal quick references and command lists
- [Troubleshooting](troubleshooting/) — Symptom → cause → fix guides

Browse the full technical reference index → [devops/README.md](../README.md)

---

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
