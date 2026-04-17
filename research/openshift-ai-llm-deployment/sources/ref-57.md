# Source: ref-57

**URL:** https://www.redhat.com/en/resources/openshift-product-lifecycles-and-eus-detail
**Fetched:** 2026-04-17 17:54:55

---

* [Home](/en "Home")
* [Resources](/en/resources "Resources")
* Understanding OpenShift product lifecycles and EUS

# Understanding OpenShift product lifecycles and EUS

June 30, 2025•

Resource type: Detail

## Introduction

Red Hat provides a comprehensive product lifecycle for Red Hat® OpenShift® Container Platform 4. It comes with 18 months of full and maintenance support, and lifecycle extensions that provide up to 36 months of support for a given minor release.

Effective management of Red Hat OpenShift Container Platform and its associated services' lifecycles is paramount for maintaining security-focused, stable, and performant enterprise-grade cloud-native environments.

Adhering to Red Hat's defined support phases—Full Support, Maintenance Support, and Extended Update Support (EUS)—is crucial for ensuring continuous access to critical security patches, essential bug fixes, and expert technical assistance. Neglecting these lifecycle events can expose organizations to significant operational risks, including severe security vulnerabilities, critical compatibility issues, and potential noncompliance with regulatory standards.

This document covers practical guidance on support phases, timing upgrades, and understanding options when approaching end-of-life dates.

## OpenShift product lifecycle basics

The OpenShift lifecycle is time-delineated and phased, supporting at least 4 minor versions concurrently. Red Hat aims for a 4-month release cadence, giving customers ample time for planning. All released errata remain accessible to active subscribers throughout the entire lifecycle.

The OpenShift Container Platform 4 lifecycle is divided into several distinct phases, each offering different levels of support and maintenance:

OpenShift lifecycle phases diagram (for illustration purposes)

Even-numbered minor releases (e.g., OpenShift Container Platform 4.12, 4.14, 4.16) typically qualify for Extended Update Support (EUS), offering longer stability periods that are essential for mission-critical applications.

### Lifecycle phase details

#### Full support

This phase starts when a minor version is generally available (GA) and lasts for 6 months, or 90 days after the GA of the next minor release, whichever is later.

During Full Support, Critical and Important Security Advisories (RHSAs) are released as they become available. Urgent and Selected High Priority Bug Fix Advisories (RHBAs) are also released, while other fixes and qualified patches may be provided through periodic updates. To receive security and bug fixes, customers are expected to upgrade to the most current supported micro (4.x.z) version.

#### Maintenance support

This phase begins after the Full Support phase and concludes 18 months after the minor version's GA. In this phase, Critical and Important RHSAs are released as they become available, and Urgent and Selected High Priority RHBAs may be released. Other Bug Fix and Enhancement Advisories (RHEAs) might be released at Red Hat’s discretion but should not be expected.

After the Maintenance Support phase ends, software and documentation remain available, but no technical support is provided, except for assistance with upgrading to a supported version. Full functionality of OpenShift clusters cannot be guaranteed for unmaintained versions.

#### Extended Update Support

Red Hat designates all even-numbered minor releases (e.g., 4.8, 4.10, 4.12, 4.14, 4.16) as Extended Update Support (EUS) releases. For EUS releases, the Full and Maintenance support phases apply with the same conditions. EUS releases are designed to simplify upgrades between EUS versions, allowing for streamlined worker node upgrades and strategies that result in fewer node reboots.

Red Hat offers optional EUS add-ons for EUS-denoted releases.

#### Extended Update Support add-on: Term 1 (EUS Term 1)

This optional, 6-month term follows the maintenance phase for the given release. It provides technical support, backports of critical and important security updates and urgent-priority bug fixes for a predefined set of minor releases. This term allows customers to remain on the same minor release of OpenShift for a total of 24 months, which is beneficial for stable production environments running mission-critical applications.

Term 1 support is included with Premium SLA subscriptions for x86-64 versions of OpenShift Kubernetes Engine, OpenShift Container Platform, and OpenShift Platform Plus. It's also available as an add-on for Standard SLA subscriptions.

#### Extended Update Support add-on: Term 2 (EUS Term 2)

This is an optional, 12-month, buy-up, add-on subscription that commences after Term 1 ends for EUS releases. It offers technical support, backports of critical and important security updates and urgent-priority bug fixes for [platform-aligned Operators](https://access.redhat.com/support/policy/updates/openshift_operators) included in OpenShift Kubernetes Engine, as well as select OpenShift Container Platform or OpenShift Platform Plus Operators. It includes the same security and bug fix commitments as Term 1.

The combination of Term 1 and Term 2 extends the total support for a minor release to 36 months (3 years), further ensuring stable production environments for critical applications.

For OpenShift Container Platform 4.12, Term 1 and Term 2 were only available on the x86\_64 architecture. However, starting with OpenShift Container Platform 4.14, these EUS add-ons include support across all supported architectures.

Customers unsure about their access to EUS add-ons or their suitability for their environment should contact their Red Hat sales representative or partner organization.

### When to consider Extended Update Support

Extended Update Support is beneficial in scenarios requiring additional time for planning and execution:

* Complex applications requiring extensive testing before updates
* Regulatory compliance that requires months of validation
* Limited maintenance windows for scheduling updates
* Resource constraints for frequent updates

## Dealing with approaching lifecycle events

When support phases near their end dates, organizations have two primary strategies: updating to current versions or purchasing extended support. As support lifecycles approach their conclusion, organizations generally opt for one of two approaches: upgrading to the latest releases or acquiring extended support agreements.

### Option 1: Staying current through updates

The preferred approach involves maintaining currency through regular updates, which provides a robust update experience that minimizes workload disruptions during an update.

#### Regularly check Red Hat’s published lifecycle dates

Check our [published lifecycle dates](https://access.redhat.com/product-life-cycles?product=OpenShift%20Container%20Platform%204). This authoritative source shows the lifecycle phases for all releases.

Product lifecycle dates page on Red Hat Customer Portal

A diagram on the page illustrates the concurrent product timelines, which can aid in update planning by visualizing different releases.

Product lifecycle timelines chart

The lifecycle dates for Red Hat OpenShift cloud services environments can be found here:

* [Red Hat OpenShift Service on AWS update lifecycle](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/introduction_to_rosa/policies-and-service-definition#rosa-life-cycle)
* [Support lifecycle for Azure Red Hat OpenShift 4](https://learn.microsoft.com/en-us/azure/openshift/support-lifecycle)

#### Plan your updates and upgrades

Moving to a newer version will often mean incremental updates/upgrades. We provide an [update graph tool](https://access.redhat.com/labs/ocpupgradegraph/) to assist with this process (requires a Red Hat Customer Portal login).

Red Hat OpenShift Container Platform Update Graph tool

The tool does not know cluster specific details. Users should always log in to a cluster to “update view” on the console.

#### Select update path

Next, you can select your source and target versions:

Red Hat OpenShift Container Platform Update Graph tool, update path selection

#### Review the update path

The system generated the recommended path. Any known issues are listed.

The system also generated initial instructions for the recommended path for both the command line and the web console interface:

Command line instructions for the update path

Web console instructions for the update path

#### Validate the update path in the console

The graph tool provided on the Red Hat Customer Portal is not connected to your environment and does not know any cluster specific details. Users are advised to also validate their update path in the cluster web console. The console has insights into the live cluster and may therefore provide additional notes beyond the update path tool:

Update path with additional hints in the cluster web console

### Option 2: Purchasing Extended Update Support

Red Hat provides long-life support add-ons for long-life releases. As we take a look at how it works, this illustration may be helpful:

#### Odd minor releases, and Red Hat OpenShift cloud services:

* Support is limited to 18 months of full support and maintenance support. No extensions are available.

#### Even minor releases (EUS releases):

* **Premium SLA subscriptions:** The EUS Term 1 phase is included (getting to a total of 24 months). EUS Term 2 requires an add-on purchase and extends the total support duration to up to 36 months.
* **Standard SLA subscriptions:** Both EUS Term 1 and EUS Term 2 phases must be purchased as add-ons for continued support.

Customers unsure about their access to EUS add-ons or their suitability for their environment should contact support, speak to their Technical Account Manager, or contact their Red Hat Sales representative or partner organization.

## Risk of running outside of supported lifecycle phases

Operating OpenShift beyond its supported lifecycle phases introduces significant operational and security risks that compound over time.

### Security vulnerabilities

The most critical risk involves unpatched security vulnerabilities. Once a version exits all support phases, Red Hat no longer provides security updates, leaving your environment exposed to known CVEs affecting Kubernetes components, container runtime vulnerabilities, and security issues.

Critical and Important Security Advisories (RHSAs) will be released as they become available during supported phases, but this protection disappears entirely once support ends.

### Loss of technical support

Beyond the end of Maintenance Support, no technical support will be provided except assistance to upgrade to a supported version. This means:

* No more bug fixes, enhancements, or certifications
* No help with troubleshooting cluster issues
* No guidance on configuration problems
* No assistance with performance optimization
* Limited help with upgrade planning (focused only on moving to supported versions)

### Compliance and legal implications

Many organizations face compliance requirements that mandate running supported software versions. Operating unsupported OpenShift versions can:

* Fail security audits
* Violate corporate governance policies—noncompliance with internal and external security policies and regulations
* Create issues with customer contractual obligations
* Cause potential files, legal proceedings, and reputational damage
* Impact certification requirements

## Recommendations for proactive lifecycle management

### Proactively plan your upgrade strategy

* **Regularly review lifecycle dates:** Always refer to the "[Red Hat OpenShift Container Platform Lifecycle Policy](https://access.redhat.com/support/policy/updates/openshift)" for the most up-to-date and authoritative view of the product lifecycle information.
* **Develop an upgrade strategy:** Every OpenShift cluster is unique, and therefore, each cluster will require its own path to upgrading. Test upgrade procedures in development environments and proactively communicate with Red Hat Technical Account Managers, your Red Hat sales representative, or your partner organization to seek information on issues.
* **Understand EUS eligibility:** Validate the availability of EUS and whether a support extension needs to be purchased. You may contact Red Hat for assistance in determining your access to EUS add-ons and their appropriateness for your specific environment.
* **Purchase EUS** for mission-critical applications that require more time before upgrading.

### Ensure continuous security and compliance

* **Prioritize upgrades** to actively supported OpenShift versions.
* **Implement robust security practices** (role-based access control, security context constraints, control plane hardening, regular security audits, etc.)
* **Plan ahead with release cadence:** Red Hat forecasts new releases at a 4-month cadence. Use this information to plan your upgrade paths in advance.
  + Establish an update cadence in the development environments before updating production clusters.
  + Update within the Full Support phase of each release. For conservative users, plan updates 2-3 months after each GA release to allow time for community feedback and initial patches.

### Use Red Hat resources for support and planning

* Consult the **OpenShift Update Graph Tool** and the **Cluster Console** for upgrade paths.
* **Review release notes and documentation** for target OpenShift versions.
* **Engage Red Hat for complex issues** via Red Hat support, [Technical Account Manager service](/en/services/support/technical-account-management "Technical account management"), or consultancy.

## Conclusion

Effective OpenShift lifecycle management balances operational stability with security and supportability requirements. While Extended Update Support provides valuable breathing room for complex environments, the most sustainable approach involves establishing regular update cadences aligned with Red Hat's 4-month release schedule.

Organizations should view lifecycle management as a strategic capability rather than a tactical response to approaching deadlines. By implementing proactive monitoring, automated testing, and clear change management processes, teams can maintain current, secure OpenShift environments while minimizing disruption to critical workloads.

## Resources

### Red Hat OpenShift Container Platform lifecycle policy

Stay informed about Red Hat OpenShift Container Platform lifecycle and support policies. Learn more about update phases, maintenance, and extended support options and ensure your OpenShift deployments are always current and secure. You can find the official policy [here on Red Hat Customer Portal](https://access.redhat.com/support/policy/updates/openshift).

### OpenShift Container Platform 4 lifecycle dates

Explore the product lifecycle for Red Hat OpenShift Container Platform 4. Find details on general availability, support end dates, and extended update support:

* [Official lifecycle dates](https://access.redhat.com/product-life-cycles?product=OpenShift%20Container%20Platform%204)
* [Red Hat OpenShift Service on AWS update lifecycle](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/introduction_to_rosa/policies-and-service-definition#rosa-life-cycle)
* [Support lifecycle for Azure Red Hat OpenShift 4](https://learn.microsoft.com/en-us/azure/openshift/support-lifecycle)

### OpenShift Operator lifecycle dates