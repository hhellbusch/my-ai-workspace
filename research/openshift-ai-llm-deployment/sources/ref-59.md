# Source: ref-59

**URL:** https://access.redhat.com/support/policy/updates/rhoai-cs/lifecycle
**Fetched:** 2026-04-17 17:54:56

---

# Red Hat OpenShift AI Cloud Service Life Cycle

## Overview

*This document applies to the current General Availability release of Red Hat OpenShift AI Cloud Service.*

Red Hat provides a published product life cycle for Red Hat OpenShift AI Cloud Service in order for customers and partners to effectively plan, deploy, and support their applications running on the platform. Red Hat publishes this life cycle in order to provide as much transparency as possible and might make exceptions from these policies as conflicts might arise.

The life cycle of Red Hat OpenShift AI Cloud Service follows a release-driven approach where a single version is available and is supported at any one time.

Red Hat OpenShift AI Cloud Service is available as an add-on to [Red Hat OpenShift Dedicated](https://cloud.redhat.com/products/dedicated/) and [Red Hat Openshift Service on AWS](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fwww.openshift.com%2Fproducts%2Famazon-openshift) and maintains a release schedule that is independent from other Red Hat products and services. More details about the OpenShift AI offering can be found in the [Red Hat OpenShift AI Service Definition](https://access.redhat.com/support/policy/updates/rhods/service).

The [Red Hat OpenShift Dedicated Life Cycle](https://access.redhat.com/support/policy/updates/openshift/dedicated/) provides information on supported versions for Red Hat OpenShift Dedicated. During the Red Hat OpenShift AI general availability period, the following OpenShift versions are supported:

* 4.18
* 4.17
* 4.16
* 4.15

## Upgrade Policy

The Red Hat OpenShift AI Add-on, and installed components, are automatically updated to the latest version available, on all clusters.

This upgrade policy includes feature releases, as well as bug and security fix releases.

## Components Life Cycle

### Data science pipelines

Starting from May 2nd 2024, the data science pipelines cloud service component is upgraded to version 2. This upgrade follows the trajectory of its upstream equivalent, KubeFlow Pipelines. Data science pipelines v2 will support pipeline versions and pipeline logs.
With the introduction of data science pipelines v2, it will no longer be possible to deploy, view, and edit the details of a data science pipelines v1 pipeline from the RHOAI dashboard.
Further information on using data science pipelines v2 are available in the RHOAI  [documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_cloud_service/1/html/working_on_data_science_projects/working-with-data-science-pipelines_ds-pipelines#enabling-data-science-pipelines-2_ds-pipelines).

## End of Life Policy

During the general availability period, Red Hat reserves the right to discontinue the service within one year advance notice. If the service is discontinued, Red Hat will persist customer data for 60 days after the service end date.