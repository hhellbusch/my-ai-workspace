# Source: ref-58

**URL:** https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle
**Fetched:** 2026-04-17 17:54:54

---

# Red Hat OpenShift AI Self-Managed Life Cycle

Contents

* [Overview](#overview)
* [Life Cycle Phases](#phases)
* [Life Cycle Dates](#dates)
* [Historic Version List](#historic)
* [Release Types](#release)

+ [Upgrade Policy](#upgradePolicy)
+ [Upgrade Strategy and Paths](#upgradeStrategy)

- [Early Access](#ea)
- [GA/Stable and GA-x.y](#ga)
- [Extended Update Support eus-x.y](#eus)

* [Migrating from 2.x to 3.x](#migration)

  

## Overview

Red Hat provides a published Product Life Cycle for Red Hat OpenShift AI (RHOAI) Self-Managed in order for customers and partners to effectively plan, deploy, and support their infrastructure and applications running on the platform. Red Hat publishes this life cycle in an effort to provide as much transparency as possible and may make exceptions from these policies as conflicts may arise.
Customers are expected to upgrade Red Hat OpenShift AI (RHOAI) to the most current supported version of the product in a timely fashion. Bug fixes and features are targeted for the latest versions of the product (Full Support Phase), See below for more information on Production Phases.

Red Hat OpenShift AI Self-Managed is available as an [Operator](https://access.redhat.com/support/policy/updates/openshift_operators) to [Red Hat OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) and maintains a release schedule that is independent from other Red Hat products and services.

The [Red Hat OpenShift Life Cycle](https://access.redhat.com/support/policy/updates/openshift) provides information on supported versions for Red Hat OpenShift.

For information on RHOAI supported configurations, see the Supported Configurations [article](https://access.redhat.com/articles/rhoai-supported-configs-3.x).

  

## Lifecycle Phases

### Full support

Full Support is provided according to the published Scope of Coverage and Service Level Agreement. Likewise, Development Support is provided according to the published Scope of Coverage and Service Level Agreement.
During the Full Support Phase, qualified [Critical and Important Security Advisories](https://access.redhat.com/security/updates/classification) (RHSAs) and Urgent and Selected High Priority Bug Fix advisories (RHBAs) will be released as they become available; all other available fix and qualified patches may be released via periodic updates. In order to receive security and bug fixes, customers are expected to upgrade their Red Hat OpenShift AI environment to the most current supported micro (3.x.z) version.

### Maintenance Support

During the Maintenance Support phase, qualified Critical and Important Security Advisories (RHSAs) will be released as they become available. Urgent and Selected High Priority Bug Fix Advisories (RHBAs) may be released as they become available. Other Bug Fix (and Enhancement (RHEA) Advisories may be released at Red Hat’s discretion, but should not be expected.

### Extended Support

During the Extended Update Support phase Red Hat will maintain component specific support. For supported components in a given release, please refer to the Supported Configurations [page](https://access.redhat.com/articles/rhoai-supported-configs).

  

## Life Cycle Dates

  
  

## Historic Version List

Versions of Red Hat OpenShift AI Self-Managed that are out of support or have reached end of life are listed on the Red Hat Customer Portal Product Life Cycles page. This page provides full Life Cycle dates for all releases, including end of Full Support and end of Extended Update Support dates.

For the complete historic version list, see [Red Hat OpenShift AI Self-Managed — Product Life Cycles](https://access.redhat.com/product-life-cycles?product=Red%20Hat%20OpenShift%20AI%20Self-Managed)

  

## Release Types

RHOAI release types, and their respective Life Cycles, generally fall under three main categories:

* Early Access releases: These releases do not have support and last for one month, or until the next release is available. They are designed to test new features.
* GA releases: These releases include Full Support for seven months. Red Hat issues a GA release every two Early Access releases. 3.4.EA1 => 3.4.EA2 => 3.4GA
* Extended Update Support (EUS) releases: These releases include Full Support for seven months followed by Extended Update Support for eleven months. Red Hat issues an EUS release every three GA releases.

### Upgrade Policy

The RHOAI operator and installed components are automatically updated to the latest version, unless the manual upgrade strategy is opted for. For more information about how to [install](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/2-latest/html/installing_and_uninstalling_openshift_ai_self-managed/index) the operator and [configure](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/upgrading_openshift_ai_self-managed/configuring-the-upgrade-strategy-for-openshift-ai_upgrade) the update strategy, see the [RHOAI Documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest). Customers are advised to deploy the latest available minor version at their earliest convenience.

### Upgrade Strategy and Paths

Customers are advised to choose their upgrade strategy according to their needs, which might vary in terms of release longevity or number of features available. When defining this strategy, it is important to consider that choosing the automatic approach ensures that customers will receive all the latest security and bug fixes for the currently supported version.
Red Hat OpenShift AI uses major (*x.*), minor (*x.y*), and micro (*x.y.z*) release versions and maintains a release schedule that is independent from other Red Hat products and services. Red Hat tests and supports upgrade paths that are allowed according to the OLM rules enforced by the operator. The customer is free to change the streaming channels accordingly.
  
**Note:** Red Hat recommends that you plan your upgrades so that you are on a supported channel at all times. You must be on the latest available version in your selected channel to receive support for Red Hat OpenShift AI.

#### *Early Access (EA)* Customers who want to try upcoming product features before a specific version is made Generally Available can now do so by deploying Early Access versions. For example, before version 3.5 of OpenShift AI is officially released, Red Hat will make 2 EA versions available to customers. They would be labelled 3.5-EA1 and 3.5-EA2. They would be released roughly 1 and 2 months before the GA version of 3.5 is available. Be advised that Red Hat does not provide support for EA versions, including security updates and CVE fixes. These deployments are recommended only where early access to new features is desirable and production support is not required. Red Hat recommends choosing this streaming channel with the automatic update strategy to receive EA drops as they are published. For Early Access releases, they are provided in the beta update channels. Important: Upgrades are not supported for EA versions. Deploying an EA drop or moving from an EA drop to a GA release will require a fresh installation. Red Hat only supports upgrades across GA versions. For example: * 3.4.0 (*GA*) -> 3.5.0 (*GA*) *GA*/*Stable* and *GA-x.y* Starting with 3.x customers who prioritize stability over new feature availability are recommended to choose the *ga*, *ga-3.x* or *ga-x.y* streaming channels. Selecting the automatic updates strategy with the GA, unnumbered channel, will result in the deployments being upgraded to the latest GA minor version as soon as it is released. This choice will reduce the overhead of updating manually as soon as a new GA release is available and will grant access to the latest GA features. Alternatively, the selection of the numbered GA channels will allow customers to plan and execute the upgrade to the next GA release while keeping their deployment under full support within a four months time window. Be advised that Red Hat supports from two to three GA releases at a given time. These types of deployments are recommended for most stage and production environments. In the *ga* and *ga-x.y* update channels, Red Hat supports single-step upgrades from the most recent previous minor GA version to the latest minor GA version. For example, users could upgrade from OpenShift AI 3.4.0 (*ga*) as follows: * 3.4.0 (*GA*) -> 3.4.1 (*GA*) * 3.4.1 (*GA*) -> 3.5.0 (*GA*) * 3.5.0 (*GA*) -> 3.5.1 (*GA*) 3.4.0 (GA) -> 3.4.1 (GA) 3.4.1 (GA) -> 3.5.0 (GA) 3.5.0 (GA) -> 3.5.1 (GA)*eus-x.y* For customers prioritizing stability, the *eus-x.y* streaming channels offer up to nine months for planning upgrades to the next Extended Update Support (EUS) release. These channels suit enterprise environments needing extended support beyond a seven-month upgrade cycle. Red Hat supports single-step upgrades between consecutive minor EUS versions. This dual approach enables seamless transitions, accommodating both stability and access to newer releases. Red Hat tests and supports upgrade paths that are allowed according to the [OLM rules](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Folm.operatorframework.io%2Fdocs%2F) enforced by the operator. The customer is free to change the streaming channels accordingly.

  

## Migrating from 2.x to 3.x

Direct upgrades from OpenShift AI 2.25 or earlier to version 3.3 and prior are not currently supported due to significant architectural changes.
For users on version 2.25, support for migration to a 3.x version is planned for an upcoming release.
For more information, see the [Why upgrades to OpenShift AI 3.0 are not supported](https://access.redhat.com/articles/7133758) Knowledgebase article.

This upgrade policy includes feature releases, as well as bug and security fix releases.