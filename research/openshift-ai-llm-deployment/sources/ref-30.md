# Source: ref-30

**URL:** https://developers.redhat.com/articles/2025/07/07/how-build-model-service-platform
**Fetched:** 2026-04-17 (WebFetch fallback)

---

# How to build a Model-as-a-Service platform

July 7, 2025

Third installment of a four-part article series on constructing a Model-as-a-Service (MaaS) platform using Red Hat technologies.

## Process overview

Uses a pre-provisioned Red Hat OpenShift Container Platform cluster with Red Hat OpenShift AI. Steps include:
1. Establishing connection to OpenShift AI (oc login, dashboard access)
2. Understanding components: Workbenches, Models, Cluster storage, Connections, Permissions
3. Review and test a pre-deployed Granite model (inspect config, connections, test endpoints via curl)
4. Deploy a new model (TinyLlama) — configure serving runtime, model server size, source model location
5. Configure 3Scale API Gateway for MaaS — manage, secure, analyze API access
6. Create new product in 3Scale using operator to automate model exposure
7. Connect application (AnythingLLM) to MaaS model
8. Explore usage analytics in 3Scale

## Key topics covered:

- OpenShift AI components: Workbenches (JupyterLab/VSCode), Models, Cluster storage, Connections, Permissions
- Model deployment: ServingRuntime configuration, model server size, S3 source location
- 3Scale API Gateway: Developer Portal, subscriptions, application creation, API docs
- Endpoint testing via curl commands
- Usage analytics and monitoring
