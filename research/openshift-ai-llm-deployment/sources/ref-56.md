# Source: ref-56

**URL:** https://learn.microsoft.com/en-us/azure/openshift/support-lifecycle
**Fetched:** 2026-04-17 17:54:53

---

Table of contents 


Exit editor mode

Ask Learn




Ask Learn




Focus mode







Table of contents
[Read in English](#)




Add




Add to plan
Edit


---

#### Share via

[Facebook](#)
[x.com](#)
[LinkedIn](#)
[Email](#)


---







Copy Markdown




Print

---

Note

Access to this page requires authorization. You can try [signing in](#) or changing directories.

Access to this page requires authorization. You can try changing directories.

# Support lifecycle for Azure Red Hat OpenShift 4

Feedback

Summarize this article for me

Red Hat releases minor versions of Red Hat OpenShift Container Platform (OCP) approximately every four months. These releases include new features and improvements. Patch releases are more frequent (typically weekly) and might include fixes for security vulnerabilities or bugs.

Azure Red Hat OpenShift is built from specific releases of OCP. This article covers the versions of OCP that are supported for Azure Red Hat OpenShift and details about updates, deprecations, and the support policy.

## Red Hat OpenShift versions

Red Hat OpenShift Container Platform uses semantic versioning. Semantic versioning uses different levels of numbers to specify different versions. The following table illustrates the different parts of a semantic version number, in this case using the example version number `4.19.16`.

| Major version (x) | Minor version (y) | Patch version (z) |
| --- | --- | --- |
| 4 | 19 | 16 |

* **Major version**: No major version releases are planned at this time. Major versions involve significant changes to the core service such as large-scale additions of new features and functions, architectural changes, and removal of existing functions.
* **Minor version**: Released approximately every four months. Minor version updates can include feature additions, enhancements, deprecations, removals, bug fixes, security enhancements, and other improvements.
* **Patch version**: Typically released each week, or as needed. Patch version updates can include bug fixes, security enhancements, and other improvements.

You should aim to run the latest minor release of the major version you're running. For example, if your production cluster is on 4.18, and 4.19 is the latest generally available minor version for the 4 series, you should update to 4.19 as soon as you can.

### Update channels

Update channels are the mechanism by which users state the OpenShift Container Platform minor version they intend to update their clusters to. Update channels are tied to a minor version of Red Hat OpenShift Container Platform. The version number in the channel represents the target minor version that the cluster will eventually be updated to. An update channel doesn't recommend updates to a version above the selected channel's version. For instance, the OCP `stable-4.18` update channel doesn't include an update to a 4.19 release. Update channels only control release selection and don't modify the current version of the cluster. For more information, see [Understanding update channels and releases](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/updating_clusters/understanding-openshift-updates-1#understanding-update-channels-releases).

Important

Azure Red Hat OpenShift provides support for `fast`, `stable`, and `eus` channels only. For example, `stable-4.19` or `eus-4.18`.

You can use the `fast`, `stable`, or `eus` channels to update from a previous minor version of Azure Red Hat OpenShift. Clusters updated using the `candidate` channel could put your cluster in a [Limited Support state](#limited-support-status).

## Azure Red Hat OpenShift version support policy

### Azure Red Hat OpenShift version availability

An Azure Red Hat OpenShift release is available through one of two mechanisms:

* When an update to a newer version is available for an existing cluster
* When a new version is available as an install target for a new cluster

### Update availability

Azure Red Hat OpenShift supports generally available (GA) minor versions of Red Hat OpenShift Container Platform from when an update is available in the OpenShift `fast` channel. Update availability can be checked at the following page, [Red Hat OpenShift Container Platform Update Graph](https://access.redhat.com/labs/ocpupgradegraph/update_path).

### Install availability

Installable versions can be validated by using the [Azure Red Hat OpenShift release calendar](#azure-red-hat-openshift-release-calendar) or by running the following Azure CLI command:

```
az aro get-versions --location [region]
```

### Supported versions policy exceptions

The Azure Red Hat OpenShift SRE team reserves the right to add or remove new or existing versions, or delay upcoming minor release versions that were identified to have one or more critical production impacting bugs or security issues without advance notice.

Specific patch releases might be skipped, or rollout might be accelerated depending on the severity of the bug or security issue.

### Mandatory updates

In extreme circumstances and based on the assessment of the Common Vulnerabilities and Exposures (CVE) criticality to the environment, you're notified that you have 72 hours to update your cluster to the latest, secure patch release. In the case that the update isn't done after 72 hours, a critical patch update might be applied to clusters automatically by Azure Red Hat OpenShift Site Reliability Engineers (SRE) which are then followed with a notification that informs you of the change. It's best practice to install patch (z-stream) updates as soon as they're available.

### Version end-of-life

End-of-life means that a version is no longer supported in a `stable` channel for odd minor versions, nor in a `eus` channel for even minor versions. The end-of-life date for a version of Azure Red Hat OpenShift can be found in the [Azure Red Hat OpenShift release calendar](#azure-red-hat-openshift-release-calendar).

Note

If you're running an unsupported Red Hat OpenShift version, you might be asked to update when requesting support for the cluster. Clusters running unsupported Red Hat OpenShift releases aren't covered by the Azure Red Hat OpenShift service-level agreement (SLA).

## Azure Red Hat OpenShift release calendar

See the following guide for the [past Red Hat OpenShift Container Platform (upstream) release history](https://access.redhat.com/support/policy/updates/openshift/#dates).

| Version | OCP GA Availability | Azure Red Hat Openshift Install Availability | Azure Red Hat Openshift End of Life (Stable channel) | Azure Red Hat OpenShift End of Life (EUS Term 1) |
| --- | --- | --- | --- | --- |
| 4.20 | October 2025 | Coming soon | April 21, 2027 | October 21, 2027 |
| 4.19 | June 2025 | December 16, 2025 | December 17, 2026 | N/A |
| 4.18 | February 2025 | November 6, 2025 | August 25, 2026 | February 25, 2027 |
| 4.17 | October 2024 | June 5, 2025 | April 1, 2026 | N/A |
| 4.16 | June 2024 | March 10, 2025 | December 27, 2025 | June 27, 2026 |
| 4.15 | February 2024 | September 4, 2024 | August 27, 2025 | N/A |

Review the following image to learn about the Azure Red Hat OpenShift support window.

* The support window for an OCP version begins with **Azure Red Hat Openshift Update Availability**.
* **Azure Red Hat Openshift Update Availability** is the date when the OCP version is available in a `fast` channel for an update from a previous version.
* **Azure Red Hat Openshift Install Availability** is the date when the version is available for a new cluster installation. For example when you create a new cluster with Azure portal or Azure CLI.
* **Azure Red Hat Openshift End of Life** is the date when a version is no longer supported in the `stable` channel for odd minor versions.
* **Azure Red Hat OpenShift End of Life (EUS)** is the date when a version is no longer supported in the `eus` channel for even minor versions.

For more information about update channels, see [Understanding update channels and releases](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/updating_clusters/understanding-openshift-updates-1#understanding-update-channels-releases).

## Extended Update Support Add-on Term 1

Extended Update Support Add-on (EUS) Term 1 is available on even-numbered minor versions starting with version 4.16, and is included with your Azure Red Hat OpenShift subscription. This provides the key benefit of extending the support lifecycle for an additional 6 month period.

To apply EUS Term 1 to your Azure Red Hat OpenShift cluster you must change your support channel to `eus-4.y`. For more information about update channels see [Understanding update channels and releases](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/updating_clusters/understanding-openshift-updates-1#understanding-update-channels-releases).

Note

Obtaining updates and support during the EUS period requires you to change your update channel to `eus-4.y`

For more information about EUS Term 1 see [Extended Update Support Add-On - Term 1](https://access.redhat.com/support/policy/updates/openshift/#eus).

## Limited support status

When a cluster transitions to a limited support status, also called outside of support, Azure Red Hat OpenShift SREs no longer proactively monitor the cluster. And, the SLA is no longer applicable and credits requested against the SLA are denied, though it doesn't mean that you no longer have product support.

A cluster might transition to a Limited Support status for many reasons, including the following scenarios:

* If you don't update a cluster to a supported version before the end-of-life date.
  + There are no runtime or SLA guarantees for versions after their end-of-life date. To avoid this and continue receiving full support, update the cluster to a supported version before the end-of-life date. If you don't update the cluster before the end-of-life date, the cluster transitions to a Limited Support status until it's updated to a supported version.
  + Azure Red Hat OpenShift SREs provide commercially reasonable support to update from an unsupported version to a supported version. However, if a supported update path is no longer available, you might have to create a new cluster and migrate your workloads.
* If you remove or replace any native Azure Red Hat OpenShift components or any other component that's installed and managed by the service.
  + If admin permissions were used, Azure Red Hat OpenShift isn't responsible for any of your or your authorized user's actions, including those actions that affect infrastructure services, service availability, or data loss. If any such actions are detected, the cluster might transition to a Limited Support status. You should then either revert the action or create a support case to explore remediation steps.
  + In some cases, the cluster can return to a fully supported status if you remediate the violating factors. However, in other cases, you might have to delete and recreate the cluster.
  + For more information, see the Azure Red Hat OpenShift support policy about [cluster configuration requirements](support-policies-v4#cluster-configuration-requirements).

## FAQ

**What happens when a user updates an OpenShift cluster with a minor version that isn't supported?**

Azure Red Hat OpenShift supports installing minor versions consistent with the dates in the previous table. A version is supported as soon as an update path to that version is available in the `fast` channel. If you're running a version past the End of Life date, you're outside of support and might be asked to update to continue receiving support. Updating from an older version to a supported version can be challenging, and in some cases not possible. We recommend you keep your cluster on the latest OpenShift version to avoid potential update issues.

For example, if the oldest supported Azure Red Hat OpenShift version is 4.16 and you are on 4.15 or older, you're outside of support. When the update from 4.15 to 4.16 or higher succeeds, you're back within our support policies.

Reverting your cluster to a previous version, or a rollback, isn't supported. Only updating to a newer version is supported.

**What does "Outside of Support" or "Limited Support" mean?**

If your cluster is running an OpenShift version that isn't on the supported versions list, or is using an [unsupported cluster configuration](support-policies-v4#cluster-configuration-requirements), your cluster is *outside of support*. As a result:

* When you open a support ticket for your cluster, you might be asked to update the cluster to a supported version before receiving support.
* Any runtime or SLA guarantees for clusters outside of support are voided.
* Clusters outside of support are patched only on a best effort basis.
* Clusters outside of support aren't monitored.

## Next steps

For more support information, see [Azure Red Hat OpenShift 4.0 support policy](support-policies-v4).

---

## Feedback

Was this page helpful?

Yes




No





No

Need help with this topic?

Want to try using Ask Learn to clarify or guide you through this topic?

Ask Learn




Ask Learn

 Suggest a fix?

---

## Additional resources

---

* Last updated on 
  2025-11-14