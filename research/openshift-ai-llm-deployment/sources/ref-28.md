# Source: ref-28

**URL:** https://developers.redhat.com/articles/2025/01/30/build-and-deploy-modelcar-container-openshift-ai
**Fetched:** 2026-04-17 (WebFetch fallback)

---

# Build and deploy a ModelCar container in OpenShift AI

January 30, 2025

## Overview

One challenge of managing models in production with RHOAI and KServe is the dependency on S3-compatible storage. Users must deploy S3-compatible storage somewhere accessible and upload their model to an S3 bucket. Managing models through S3 creates new challenges for traditional operations teams.

OpenShift AI 2.14 enabled the ability to serve models directly from a container using KServe's ModelCar capabilities. OpenShift AI 2.16 added the ability to deploy a ModelCar image from the dashboard.

## How to build a ModelCar container

ModelCar container requirements are simple: model files must be located in a `/models` folder of the container. No additional packages or files required.

### Two-stage build process:

**Stage 1:** Install huggingface-hub, download model files using `snapshot_download` with `allow_patterns=["*.safetensors", "*.json", "*.txt"]`

**Stage 2:** Copy model files from first stage into a minimal container (ubi9/ubi-micro)

### Build and push:
```
podman build . -t modelcar-example:latest --platform linux/amd64
podman push modelcar-example:latest quay.io/<registry>/modelcar-example:latest
```

## Deploy with OpenShift AI dashboard

Uses vLLM ServingRuntime for KServe. Connection URI format: `oci://quay.io/redhat-ai-services/modelcar-catalog:granite-3.1-2b-instruct`

Default KNative Serving timeout is 10 minutes. Can be extended via `serving.knative.dev/progress-deadline: 30m` annotation.

## Pros:

- Standardizes model delivery between environments using existing container image management technologies and automation
- Models become as portable as any other container image
- Once cached on node, vLLM startup significantly faster than from S3-compatible storage

## Cons:

- LLM size creates large container images: Granite 2B ~5GB, Granite 8B ~15GB, Llama 3.1 405b ~900GB
- Building large containers requires significant resources
- Pulling very large images can overwhelm a node's local cache

## Resources:

- Red Hat AI Services ModelCar Catalog repo on GitHub
- ModelCar Catalog registry on Quay: quay.io/repository/redhat-ai-services/modelcar-catalog
