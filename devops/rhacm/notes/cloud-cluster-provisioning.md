---
review:
  status: unreviewed
  notes: "AI-generated 2026-10-16 from ACM 2.16 Clusters and Networking, and OCP 4.20 account and firewall chapters. Endpoint lists and credential fields are doc-sourced. Not yet validated against a live hub creating an AWS, Azure, or GCP cluster."
---

# ACM Cloud Cluster Provisioning — AWS, Azure, and GCP

Working reference for getting an ACM hub to create self-managed OpenShift clusters on Amazon Web Services, Microsoft Azure, and Google Cloud.

**Audience:** Platform engineers preparing a hub, a cloud account, and a firewall request so ACM can create clusters.

**Purpose:** List what must exist before the first create, and which network paths have to be open between the hub and the clouds.

**Scope:** Installer-provisioned OpenShift clusters created by Hive. ACM 2.16 calls this out in [Clusters](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/clusters/index), section 1.15.3, Creating clusters: the multicluster engine uses the Hive operator from OpenShift to provision every provider except on-premises clusters and hosted control planes.

Hosted control planes (HyperShift) and Red Hat managed services (ROSA, Azure Red Hat OpenShift, OpenShift Dedicated) use other procedures. On-prem agent installs use CIM — [cim-hub-setup.md](./cim-hub-setup.md). Day-2 hub ↔ spoke ports after the cluster exists are in [networking-requirements-2.16.md](./networking-requirements-2.16.md).

Account IAM detail lives in the OpenShift 4.20 install books linked below. This note records the decisions and the firewall-facing paths, and points at those chapters for the full permission lists.

---

## What the hub already provides

`hive` and `cluster-lifecycle` are enabled by default on the `MultiClusterEngine`. `cluster-api` and `cluster-api-provider-aws` are disabled by default. Those Cluster API components are a separate lifecycle path. The console flow **Infrastructure > Clusters > Create cluster** for AWS, Azure, and GCP uses Hive.

No `AgentServiceConfig` is required.

Confirm on the hub:

```bash
oc get multiclusterengine multiclusterengine -n multicluster-engine
oc get pods -n hive
oc get clusterimageset
```

`ClusterImageSet` resources are the release images the console offers. On a connected hub the `cluster-image-set-controller` fills that list. An empty list means the hub cannot see `quay.io/openshift-release-dev` (or the configured mirror). See Clusters, section 1.15.2, Release images.

Hive copies the cloud credential into the managed-cluster namespace and runs the OpenShift installer from a pod on the hub. Egress for create and destroy leaves from the hub node network (the nodes where those pods run, or the hub's egress NAT), not from the ACM console route.

---

## Shared prerequisites

From Clusters, section 1.14, Managing credentials:

- A running hub with outbound internet, or a proxy that can reach the provider APIs and the release registry.
- Edit access on the hub for the person or automation creating the credential.
- One credential per provider account, and a separate credential per base domain on that account.
- A Red Hat OpenShift pull secret and an SSH key pair on the credential.
- An optional base DNS domain on the credential. When set, cluster creation pre-fills it.
- A public DNS zone that is authoritative for that base domain, in the same provider account (GCP: in the same project). Delegate the zone at the registrar, or delegate the subdomain from the parent zone, before the first create.

The credential is a Kubernetes secret. Changing the pull secret, SSH keys, or base domain later does not update clusters already provisioned with the original values. If the cloud access key expires, update the credential on the hub before destroy. Destroy calls the same cloud APIs as create.

---

## AWS

Credential fields: access key ID and secret access key. Console and API steps are Clusters, sections 1.14.1 and 1.14.2.

Account preparation is [Configuring an AWS account](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_aws/installing-aws-account), OpenShift Container Platform 4.20, chapter 2:

- A public Route 53 hosted zone for the base domain.
- An IAM user with programmatic access. `AdministratorAccess` covers the installer. Section 2.3 lists the narrower permission set. The user needs `tag:GetResources` in `us-east-1`, because the installer acts in that region even when the cluster is elsewhere.
- Service quotas for a default cluster: its own VPC, a NAT gateway and elastic IP per availability zone, load balancers, and the control-plane and worker instances (`m6i.xlarge` and `m6i.large` in most regions). Chapter 2 calls out the elastic IP limit in `us-east-1` as too low for the default layout.

Cluster creation is Clusters, section 1.15.3.3, Creating a cluster on Amazon Web Services. GovCloud is section 1.15.3.4 and adds VPC and PrivateLink setup that the commercial path does not.

---

## Azure

Credential fields: `AzurePublicCloud` or `AzureUSGovernmentCloud`, base domain resource group (the resource group that holds the DNS zone; Azure portal **Home > DNS Zones**), client ID, client secret, subscription ID, and tenant ID. Console and API steps are Clusters, sections 1.14.3 and 1.14.4.

The console procedure creates the service principal with Contributor on the subscription:

```bash
az ad sp create-for-rbac --role Contributor \
  --name <service_principal> \
  --scopes /subscriptions/<subscription_id>
```

Account preparation is [Configuring an Azure account](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_azure/installing-azure-account), OpenShift Container Platform 4.20, chapter 2:

- A public Azure DNS zone for the base domain.
- The identity that installs needs Contributor and User Access Administrator on the subscription. User Access Administrator is what lets the installer assign roles to the cluster's own identity. Chapter 2, section 2.4.1, says that role can be omitted when `identity.type` is `None`. The ACM credential steps do not set that field.
- The account that creates the service principal needs Contributor, User Access Administrator, and permission to create service principals in Microsoft Entra ID.
- vCPU quota. A default cluster uses 44 vCPUs (bootstrap and three control planes on `Standard_D8s_v3`, three workers on `Standard_D4s_v3`). Many subscriptions start at 20 vCPUs per region.

Cluster creation is Clusters, section 1.15.3.5, Creating a cluster on Microsoft Azure.

---

## Google Cloud

Credential fields: project ID and a service account JSON key. Console and API steps are Clusters, sections 1.14.5 and 1.14.6.

Account preparation is [Configuring a Google Cloud project](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_google_cloud/installing-gcp-account), OpenShift Container Platform 4.20, chapter 2:

- Enable these APIs in the project that will host the cluster: Compute Engine (`compute.googleapis.com`), Cloud Resource Manager, Cloud DNS, IAM Service Account Credentials, IAM, and Service Usage.
- A public Cloud DNS zone in that same project.
- A service account key. The Owner role covers install. The narrower role set in section 2.5.1 is Compute Admin, Role Administrator, Security Admin, Service Account Admin, Service Account Key Admin, Service Account User, Storage Admin, and DNS Administrator when the installer creates the network.
- CPU, static IP, and SSD persistent-disk quotas. Chapter 2 notes that some regions exceed the default storage quota for a normal cluster.

Cluster names cannot start with `goog` or contain a `google`-like string. Cluster creation is Clusters, section 1.15.3.6, Creating a cluster on Google Cloud Platform.

---

## Network paths

Create fails when the hub can manage spokes it already imported and still cannot call the cloud or reach the new API. The ongoing hub ↔ managed-cluster ports are necessary and are not the whole list.

Source for ports 6443 and 443 between hub and managed cluster: [Networking](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/networking/index), ACM 2.16, sections 1.1 and 1.2, and the MCE table in Clusters (Hive and `import-controller` to the provisioned API on 6443; klusterlet back to the hub API on 6443).

Source for provider hosts: [Configuring your firewall](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installation_configuration/configuring-firewall), OpenShift Container Platform 4.20, chapter 2, section 2.1. That chapter is written for the cluster under install. With ACM, the installer runs on the hub, so the same provider hosts must be reachable from hub egress for the duration of create and destroy. The new cluster's nodes need them too, from the new VPC or VNet.

### Who initiates what

```text
hub nodes (Hive provision pod)
  |-- TCP 443 --> provider APIs          create and destroy
  |-- TCP 443 --> release registry       pull the OpenShift payload
  |-- TCP 6443 -> api.<name>.<base>      finish install, install klusterlet

new cluster nodes
  |-- TCP 6443 --> hub Kubernetes API    klusterlet
  |-- TCP 443  --> hub ingress route     metrics and alerts
  |-- TCP 443  --> provider APIs         Machine API, Cloud Credential Operator
  |-- TCP 443  --> Red Hat registries    images, release signatures

hub nodes
  |-- TCP 443 --> managed cluster route  search log retrieval (day 2)
```

Firewall rules should name the hub's node egress addresses or NAT, because Hive pods use the node network.

### Paths to open

| From | To | Port | When |
|---|---|---|---|
| Hub egress | Provider API hosts in the tables below | TCP 443 | Create and destroy |
| Hub egress | Release image registry (`quay.io`, `cdn.quay.io`, `cdn01`–`cdn06.quay.io`, or the mirror in use) | TCP 443 | Create |
| Hub egress | `api.<cluster>.<base-domain>` | TCP 6443 | From the moment the API load balancer exists, through import |
| New cluster nodes | Hub Kubernetes API address | TCP 6443 | Once the API is up |
| New cluster nodes | Hub ingress route | TCP 443 | After import, for metrics and alerts |
| Hub egress | Managed cluster ingress route | TCP 443 | Day-2 log retrieval |
| New cluster nodes | The same provider API hosts, plus the Red Hat registry and signature hosts in the firewall chapter | TCP 443 | Install and steady state, from the new VPC or VNet |

The hub must resolve the provider hostnames and, after the installer publishes records, `api.<cluster>.<base-domain>`. A split-horizon resolver that never sees the public zone leaves Hive waiting on a name the cloud already created.

When the cluster API is published as External, the 6443 target is the public API load balancer. When it is published as Internal, that target is a private address, and the hub needs a private route to it (peering, VPN, or transit).

The OpenShift network flow matrix marks TCP 22 to nodes as optional. Create and import use 443 and 6443. Port 22 is the path for SSH-based install debugging.

Machine Config Server TCP 22623 stays inside the new cluster, between nodes and the bootstrap. It is not a hub-to-cloud rule.

AWS GovCloud and Azure Government use different API hosts from the commercial tables below. Clusters, section 1.15.3.4, is the GovCloud procedure. The firewall chapter tells you to take the exact regional endpoints from the provider's endpoint list for the partition you use.

### AWS hosts (TCP 443)

Section 2.1 allows `*.amazonaws.com`, or the explicit set:

| Host | Why it is on the list |
|---|---|
| `ec2.amazonaws.com`, `ec2.us-east-1.amazonaws.com`, `ec2.<region>.amazonaws.com` | Install and manage. `us-east-1` is also used while listing regions. |
| `elasticloadbalancing.<region>.amazonaws.com` | Load balancers |
| `iam.amazonaws.com` | IAM |
| `route53.amazonaws.com` | Cluster DNS records |
| `sts.amazonaws.com`, `sts.<region>.amazonaws.com` | Token service |
| `*.s3.amazonaws.com`, `*.s3.<region>.amazonaws.com`, `*.s3.dualstack.<region>.amazonaws.com` | Installer and registry buckets |
| `events.amazonaws.com` | Install and manage |
| `tagging.us-east-1.amazonaws.com` | Always `us-east-1`, whichever region the cluster uses |
| `tagging.<region>.amazonaws.com` | Resource tags |
| `servicequotas.<region>.amazonaws.com` | Quota checks |
| `aws.amazon.com` | Listed separately from `*.amazonaws.com` |
| `*.cloudfront.net` | Required when using STS with a private S3 bucket |

### Azure hosts (TCP 443)

Section 2.1 names:

| Host | Why it is on the list |
|---|---|
| `management.azure.com` | Azure Resource Manager |
| `*.blob.core.windows.net` | Ignition files |

The same section says to check the Azure REST reference for the exact endpoints of the APIs you call. The ACM credential is a service principal. The installer exchanges that secret at the Microsoft Entra token host (`login.microsoftonline.com` on Azure public cloud) before it calls Resource Manager. That host is not its own row in the 4.20 table. A host allowlist that omits it fails at authentication.

### Google Cloud hosts (TCP 443)

| Host | Why it is on the list |
|---|---|
| `*.googleapis.com` | Compute, DNS, IAM, and the other enabled APIs. Includes `oauth2.googleapis.com` and `storage.googleapis.com`. |
| `accounts.google.com` | Account access |

`storage.googleapis.com/openshift-release` is also a release-signature source in the general registry list. It falls under `*.googleapis.com`.

### New cluster egress to Red Hat

The firewall chapter's registry list applies to the new nodes (and to the hub, for the release pull). Minimum for a connected install:

| Host | Port |
|---|---|
| `registry.redhat.io`, `registry.access.redhat.com`, `access.redhat.com` | 443 |
| `quay.io`, `cdn.quay.io`, `cdn01.quay.io` through `cdn06.quay.io` | 443 |
| `mirror.openshift.com`, `rhcos.mirror.openshift.com` | 443 |
| `api.openshift.com`, `console.redhat.com`, `sso.redhat.com` | 443 |

Telemetry hosts (`cert-api.access.redhat.com`, `api.access.redhat.com`, `infogw.api.openshift.com`) apply when Telemetry stays enabled. NTP, if left on the default Red Hat pool, is UDP 123 to `1.rhel.pool.ntp.org`, `2.rhel.pool.ntp.org`, and `3.rhel.pool.ntp.org`, from the new nodes.

### Two different proxies

The hub cluster proxy and the proxy stored on the cloud credential are different objects.

Hive pods on the hub use the hub cluster proxy (the cluster-wide `Proxy` object) to reach provider APIs and the release registry. Allow those hosts on that proxy, or put private endpoints in `noProxy`.

The proxy fields on the credential are copied into the new cluster's `install-config`. They control egress from the cluster being built. On AWS, if the new VPC uses VPC endpoints for EC2, Elastic Load Balancing, and S3, those endpoint hosts belong in that cluster's `noProxy`. That requirement is in [Installer-provisioned infrastructure](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installing_on_aws/installer-provisioned-infrastructure), OpenShift Container Platform 4.20, chapter 3.

---

## Create

1. Credential exists for the account and base domain.
2. The DNS zone is delegated.
3. The paths above are open from hub egress and from the network the new nodes will use.
4. `oc get clusterimageset` shows a release you intend to install.
5. **Infrastructure > Clusters > Create cluster.** Pick the provider, the credential, the release image, region, and node pools.

The controller creates a namespace for that cluster. Hive provisions it and ACM imports it. There is no separate `oc import` step. With no cluster set selected, the managed cluster joins the `default` `ManagedClusterSet`.

Destroy uses the hub's path to the provider APIs. Keep that path, and a valid credential, for as long as ACM should be able to delete the cluster.

---

## Related

- [networking-requirements-2.16.md](./networking-requirements-2.16.md) — ongoing hub ↔ managed cluster ports
- [cim-hub-setup.md](./cim-hub-setup.md) — on-prem provisioning, which uses CIM instead of this path
- [Clusters](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/clusters/index) — ACM 2.16, sections 1.14 and 1.15.3
- [Networking](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/networking/index) — ACM 2.16, hub and managed cluster tables
- [Configuring your firewall](https://docs.redhat.com/en/documentation/openshift_container_platform/4.20/html/installation_configuration/configuring-firewall) — OpenShift Container Platform 4.20, chapter 2

*This content was created with AI assistance. See [AI-DISCLOSURE.md](../../../AI-DISCLOSURE.md) for how to interpret AI-generated content in this workspace.*
