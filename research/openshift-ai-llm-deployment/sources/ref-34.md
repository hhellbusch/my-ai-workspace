# Source: ref-34

**URL:** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html-single/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/index
**Fetched:** 2026-04-17 17:54:46

---

1. [Home](/)
2. [Products](/en/products)
3. [Red Hat OpenShift AI Self-Managed](/en/documentation/red_hat_openshift_ai_self-managed/)
4. [2.25](/en/documentation/red_hat_openshift_ai_self-managed/2.25/)
5. Installing and uninstalling OpenShift AI Self-Managed in a disconnected environment

# Installing and uninstalling OpenShift AI Self-Managed in a disconnected environment

---

Red Hat OpenShift AI Self-Managed 2.25

## Install and uninstall OpenShift AI Self-Managed in a disconnected environment

[Legal Notice](#idm139632266995760)

**Abstract**

Install and uninstall OpenShift AI Self-Managed on your OpenShift cluster in a disconnected environment.

---

## [Preface](#idm139632267705952) Copy linkLink copied to clipboard!

Learn how to use both the OpenShift CLI (`oc`) and web console to install Red Hat OpenShift AI Self-Managed on your OpenShift cluster in a disconnected environment. To uninstall the product, learn how to use the recommended command-line interface (CLI) method.

Note

Red Hat does not support installing more than one instance of OpenShift AI on your cluster.

Red Hat does not support installing the Red Hat OpenShift AI Operator on the same cluster as the Red Hat OpenShift AI Add-on.

## [Chapter 1. Architecture of OpenShift AI Self-Managed](#architecture-of-openshift-ai-self-managed_install) Copy linkLink copied to clipboard!

Red Hat OpenShift AI Self-Managed is an Operator that is available in a self-managed environment, such as Red Hat OpenShift Container Platform, or in Red Hat-managed cloud environments such as Red Hat OpenShift Dedicated (with a Customer Cloud Subscription for AWS or GCP), Red Hat OpenShift Service on Amazon Web Services (ROSA classic or ROSA HCP), or Microsoft Azure Red Hat OpenShift.

OpenShift AI integrates the following components and services:

* At the service layer:

  OpenShift AI dashboard
  :   A customer-facing dashboard that shows available and installed applications for the OpenShift AI environment as well as learning resources such as tutorials, quick starts, and documentation. Administrative users can access functionality to manage users, clusters, workbench images, accelerator profiles, hardware profiles, and model-serving runtimes. Data scientists can use the dashboard to create projects to organize their data science work.

      Important

      By default, hardware profiles are hidden in the dashboard navigation menu and user interface, while accelerator profiles remain visible. In addition, user interface components associated with the deprecated accelerator profiles functionality are still displayed. To show the **Settings → Hardware profiles** option in the dashboard navigation menu, and the user interface components associated with hardware profiles, set the `disableHardwareProfiles` value to `false` in the `OdhDashboardConfig` custom resource (CR) in OpenShift. For more information about setting dashboard configuration options, see [Customizing the dashboard](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/managing_resources/customizing-the-dashboard).

  Model serving
  :   Data scientists can deploy trained machine-learning models to serve intelligent applications in production. After deployment, applications can send requests to the model using its deployed API endpoint.

  Data science pipelines
  :   Data scientists can build portable machine learning (ML) workflows with data science pipelines 2.0, using Docker containers. With data science pipelines, data scientists can automate workflows as they develop their data science models.

  Jupyter (self-managed)
  :   A self-managed application that allows data scientists to configure a basic standalone workbench and develop machine learning models in JupyterLab.

  Distributed workloads
  :   Data scientists can use multiple nodes in parallel to train machine-learning models or process data more quickly. This approach significantly reduces the task completion time, and enables the use of larger datasets and more complex models.

  Retrieval-Augmented Generation (RAG)
  :   Data scientists and AI engineers can leverage Retrieval-Augmented Generation (RAG) capabilities provided by the integrated Llama Stack Operator. By combining large language model inference, semantic retrieval, and vector database storage, data scientists and AI engineers can obtain tailored, accurate, and verifiable answers to complex queries based on their own datasets within a data science project.
* At the management layer:

  The Red Hat OpenShift AI Operator
  :   A meta-operator that deploys and maintains all components and sub-operators that are part of OpenShift AI.

When you install the Red Hat OpenShift AI Operator in the OpenShift cluster using the predefined projects, the following new projects are created:

* The `redhat-ods-operator` project contains the Red Hat OpenShift AI Operator.
* The `redhat-ods-applications` project includes the dashboard and other required components of OpenShift AI.
* The `rhods-notebooks` project is where basic workbenches are deployed by default.

You can specify custom projects if needed. You or your data scientists must also create additional projects for the applications that will use your machine learning models.

Do not install independent software vendor (ISV) applications in namespaces associated with OpenShift AI.

## [Chapter 2. Understanding update channels](#understanding-update-channels_install) Copy linkLink copied to clipboard!

You can use update channels to specify which Red Hat OpenShift AI minor version you intend to update your Operator to. Update channels also allow you to choose the timing and level of support your updates have through the `fast`, `stable`, `stable-x.y` `eus-x.y`, and `alpha` channel options.

The subscription of an installed Operator specifies the update channel, which is used to track and receive updates for the Operator. You can change the update channel to start tracking and receiving updates from a newer channel. For more information about the release frequency and the lifecycle associated with each of the available update channels, see the [Red Hat OpenShift AI Self-Managed Life Cycle](https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle) Knowledgebase article.

Expand

| Channel | Support | Release frequency | Recommended environment |
| --- | --- | --- | --- |
| `fast` | One month of full support | Every month | Production environments with access to the latest product features.  Select this streaming channel with automatic updates to avoid manually upgrading every month. |
| `stable` | Three months of full support | Every three months | Production environments with stability prioritized over new feature availability.  Select this streaming channel with automatic updates to access the latest stable release and avoid manually upgrading. |
| `stable-x.y` | Seven months of full support | Every three months | Production environments with stability prioritized over new feature availability.  Select numbered stable channels (such as `stable-2.10`) to plan and upgrade to the next stable release while keeping your deployment under full support. |
| `eus-x.y` | Seven months of full support followed by Extended Update Support for eleven months | Every nine months | Enterprise-grade environments that cannot upgrade within a seven month window.  Select this streaming channel if you prioritize stability over new feature availability. |
| `alpha` | One month of full support | Every month | Development environments with early-access features that might not be functionally complete.  Select this channel to use early-access features to test functionality and provide feedback during the development process. Early-access features are not supported with Red Hat production service level agreements (SLAs).  For more information about the support scope of Red Hat Technology Preview features, see [Technology Preview Features Support Scope](https://access.redhat.com/support/offerings/techpreview/).  For more information about the support scope of Red Hat Developer Preview features, see [Developer Preview Features Support Scope](https://access.redhat.com/support/offerings/devpreview/). |

Show more

Note

The `embedded` and `beta` channels are legacy channels that will be removed in a future release. Do not select the `embedded` or `beta` channels for a new Operator installation.

## [Chapter 3. Deploying OpenShift AI in a disconnected environment](#deploying-openshift-ai-in-a-disconnected-environment_install) Copy linkLink copied to clipboard!

Read this section to understand how to deploy Red Hat OpenShift AI as a development and testing environment for data scientists in a disconnected environment. Disconnected clusters are on a restricted network, typically behind a firewall. In this case, clusters cannot access the remote registries where Red Hat provided OperatorHub sources reside. Instead, the Red Hat OpenShift AI Operator can be deployed to a disconnected environment using a private registry to mirror the images.

Installing OpenShift AI in a disconnected environment involves the following high-level tasks:

1. Confirm that your OpenShift cluster meets all requirements. See [Requirements for OpenShift AI Self-Managed](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#requirements-for-openshift-ai-self-managed_install).
2. Mirror images to a private registry. See [Mirroring images to a private registry for a disconnected installation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#mirroring-images-to-a-private-registry-for-a-disconnected-installation_install).
3. Install the Red Hat OpenShift AI Operator. See [Installing the Red Hat OpenShift AI Operator](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-the-openshift-data-science-operator_operator-install).
4. Install OpenShift AI components. See [Installing and managing Red Hat OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-and-managing-openshift-ai-components_component-installs).
5. Configure user and administrator groups to provide user access to OpenShift AI. See [Adding users to OpenShift AI user groups](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/managing_openshift_ai/managing-users-and-groups#adding-users-to-user-groups_managing-rhoai).
6. Provide your users with the URL for the OpenShift cluster on which you deployed OpenShift AI. See [Accessing the OpenShift AI dashboard](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/accessing-the-dashboard_install).
7. Optionally, configure and enable your accelerators in OpenShift AI to ensure that your data scientists can use compute-heavy workloads in their models. See [Enabling accelerators](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/enabling-accelerators_install).

### [3.1. Requirements for OpenShift AI Self-Managed](#requirements-for-openshift-ai-self-managed_install) Copy linkLink copied to clipboard!

You must meet the following requirements before you can install Red Hat OpenShift AI on your Red Hat OpenShift cluster in a disconnected environment:

**Product subscriptions**

* You must have a subscription for Red Hat OpenShift AI Self-Managed.

  Contact your Red Hat account manager to purchase new subscriptions. If you do not yet have an account manager, complete the form at [https://www.redhat.com/en/contact](https://www.redhat.com/en/contact/) to request one.

**Cluster administrator access to your OpenShift cluster**

* You must have an OpenShift cluster with cluster administrator access. Use an existing cluster or create a cluster by following the OpenShift Container Platform documentation: [Installing a cluster in a disconnected environment](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/installing-disconnected-environments).
* After you install a cluster, configure the Cluster Samples Operator by following the OpenShift Container Platform documentation: [Configuring Samples Operator for a restricted cluster](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/images/configuring-samples-operator#samples-operator-restricted-network-install).
* Your cluster must have at least 2 worker nodes with at least 8 CPUs and 32 GiB RAM available for OpenShift AI to use when you install the Operator. To ensure that OpenShift AI is usable, additional cluster resources are required beyond the minimum requirements.
* To use OpenShift AI on single node OpenShift, the node has to have at least 32 CPUs and 128 GiB RAM.
* Your cluster is configured with a default storage class that can be dynamically provisioned.

  Confirm that a default storage class is configured by running the `oc get storageclass` command. If no storage classes are noted with `(default)` beside the name, follow the OpenShift Container Platform documentation to configure a default storage class: [Changing the default storage class](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/postinstallation_configuration/post-install-storage-configuration#change-default-storage-class_post-install-storage-configuration). For more information about dynamic provisioning, see [Dynamic provisioning](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/storage/dynamic-provisioning).
* Open Data Hub must not be installed on the cluster.

For more information about managing the machines that make up an OpenShift cluster, see [Overview of machine management](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/machine_management/overview-of-machine-management).

**An identity provider configured for OpenShift**

* Red Hat OpenShift AI uses the same authentication systems as Red Hat OpenShift Container Platform. See [Understanding identity provider configuration](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/authentication_and_authorization/understanding-identity-provider) for more information on configuring identity providers.
* Access to the cluster as a user with the `cluster-admin` role; the `kubeadmin` user is not allowed. To assign `cluster-admin` privileges to a user, follow the steps in the relevant OpenShift documentation:

  + OpenShift Container Platform: [Creating a cluster admin](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/authentication_and_authorization/using-rbac#creating-cluster-admin_using-rbac)
  + OpenShift Dedicated: [Managing OpenShift Dedicated administrators](https://docs.redhat.com/en/documentation/openshift_dedicated/4/html/authentication_and_authorization/osd-admin-roles#dedicated-administrators-adding-user_osd-admin-roles)
  + ROSA: [Creating a cluster administrator user for quick cluster access](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws_classic_architecture/4/html/getting_started/rosa-quickstart-guide-ui)

**Internet access on the mirroring machine**

* Along with Internet access, the following domains must be accessible to mirror images required for the OpenShift AI Self-Managed installation:

  + `cdn.redhat.com`
  + `subscription.rhn.redhat.com`
  + `registry.access.redhat.com`
  + `registry.redhat.io`
  + `quay.io`
* For environments that build or customize CUDA-based images using NVIDIA’s base images, or that directly pull artifacts from the NVIDIA NGC catalog, the following domains must also be accessible:

  + `ngc.download.nvidia.cn`
  + `developer.download.nvidia.com`

Note

Access to these NVIDIA domains is not required for standard OpenShift AI Self-Managed installations. The CUDA-based container images used by OpenShift AI are prebuilt and hosted on Red Hat’s registry at `registry.redhat.io`.

**Create custom namespaces**

* By default, OpenShift AI uses predefined namespaces, but you can define custom namespaces for the operator, applications, and workbenches if needed. Namespaces created by OpenShift AI typically include `openshift` or `redhat` in their name. Do not rename these system namespaces because they are required for OpenShift AI to function properly. If you are using custom namespaces, before installing the OpenShift AI Operator, you must have created and labeled them as required.
* Before you can execute a pipeline in a disconnected environment, you must upload the images to your private registry. For more information, see [Mirroring images to run pipelines in a restricted environment](https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/1.15/html/creating_cicd_pipelines/creating-applications-with-cicd-pipelines#op-mirroring-images-to-run-pipelines-in-restricted-environment_creating-applications-with-cicd-pipelines).
* You can store your pipeline artifacts in an S3-compatible object storage bucket so that you do not consume local storage. To do this, you must first configure write access to your S3 bucket on your storage account.
* If you are installing OpenShift AI on a cluster running in FIPS mode, any custom container images for data science pipelines must be based on UBI 9 or RHEL 9. This ensures compatibility with FIPS-approved pipeline components and prevents errors related to mismatched OpenSSL or GNU C Library (glibc) versions.

**Install KServe dependencies**

* To support the KServe component, which is used by the single-model serving platform to serve large models, you must also install Operators for Red Hat OpenShift Serverless and Red Hat OpenShift Service Mesh and perform additional configuration. For more information, see [About the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install##About-the-single-model-serving-platform_component-install).
* If you want to add an authorization provider for the single-model serving platform, you must install the `Red Hat - Authorino` Operator. For information, see [Adding an authorization provider for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#adding-an-authorization-provider_component-install).

**Install RAG dependencies**

If you plan to deploy Retrieval-Augmented Generation (RAG) workloads by using Llama Stack, you must meet the following requirements:

* You have GPU-enabled nodes available on your cluster and you have installed the Node Feature Discovery Operator and NVIDIA GPU Operator. For more information, see [Installing the Node Feature Discovery Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator#installing-the-node-feature-discovery-operator_psap-node-feature-discovery-operator) and [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/managing_openshift_ai/enabling-accelerators#enabling-nvidia-gpus_managing-rhoai).
* You have access to storage for your model artifacts.
* You have met the KServe installation prerequisites.

**Access to object storage**

* Components of OpenShift AI require or can use S3-compatible object storage such as AWS S3, MinIO, Ceph, or IBM Cloud Storage. An object store is a data storage mechanism that enables users to access their data either as an object or as a file. The S3 API is the recognized standard for HTTP-based access to object storage services.
* The object storage must be accessible to your OpenShift cluster. Deploy the object storage on the same disconnected network as your cluster.
* Object storage is required for the following components:

  + Single- or multi-model serving platforms, to deploy stored models. See [Deploying models on the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/deploying_models/deploying_models_on_the_single_model_serving_platform#deploying-models-on-the-single-model-serving-platform_rhoai-user) or [Deploying a model by using the multi-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/deploying_models/deploying_models_on_the_multi_model_serving_platform#deploying-a-model-using-the-multi-model-serving-platform_rhoai-user).
  + Data science pipelines, to store artifacts, logs, and intermediate results. See [Configuring a pipeline server](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_data_science_pipelines/managing-data-science-pipelines_ds-pipelines#configuring-a-pipeline-server_ds-pipelines) and [About pipeline logs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_data_science_pipelines/working-with-pipeline-logs_ds-pipelines#about-pipeline-logs_ds-pipelines).
* Object storage can be used by the following components:

  + Workbenches, to access large datasets. See [Adding a connection to your data science project](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_on_data_science_projects/using-project-workbenches_projects#adding-a-connection-to-your-data-science-project_projects).
  + Distributed workloads, to pull input data from and push results to. See [Running distributed data science workloads from data science pipelines](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_distributed_workloads/running-ray-based-distributed-workloads_distributed-workloads#running-distributed-data-science-workloads-from-ds-pipelines_distributed-workloads).
  + Code executed inside a pipeline. For example, to store the resulting model in object storage. See [Overview of pipelines in Jupyterlab](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_data_science_pipelines/working-with-pipelines-in-jupyterlab_ds-pipelines#overview-of-pipelines-in-jupyterlab_ds-pipelines).

### [3.2. Mirroring images to a private registry for a disconnected installation](#mirroring-images-to-a-private-registry-for-a-disconnected-installation_install) Copy linkLink copied to clipboard!

You can install the Red Hat OpenShift AI Operator to your OpenShift cluster in a disconnected environment by mirroring the required container images to a private container registry. After mirroring the images to a container registry, you can install Red Hat OpenShift AI Operator by using OperatorHub.

You can use the *mirror registry for Red Hat OpenShift*, a small-scale container registry, as a target for mirroring the required container images for OpenShift AI in a disconnected environment. Using the mirror registry for Red Hat OpenShift is optional if another container registry is already available in your installation environment.

**Prerequisites**

* You have cluster administrator access to a running OpenShift Container Platform cluster, version 4.16 or greater.
* You have credentials for Red Hat OpenShift Cluster Manager (<https://console.redhat.com/openshift/>).
* Your mirroring machine is running Linux, has 100 GB of space available, and has access to the Internet so that it can obtain the images to populate the mirror repository.
* You have installed the OpenShift CLI (`oc`).
* You have reviewed the component requirements and identified all operators you must mirror in addition to the Red Hat OpenShift AI Operator. See [Requirements for OpenShift AI Self-Managed](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#requirements-for-openshift-ai-self-managed_install). For example:

  + If you plan to use NVIDIA GPUs, you must mirror deployed the NVIDIA GPU Operator. See [Configuring the NVIDIA GPU Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/virtualization/managing-vms#configuring-nvidia-gpu-operator_virt-configuring-virtual-gpus) in the OpenShift Container Platform documentation.
  + If you plan to use the single-model serving platform to serve large models, you must mirror the Operators for Red Hat OpenShift Serverless and Red Hat OpenShift Service Mesh.
  + If you plan to use the distributed workloads component, you must mirror the Ray cluster image.

Note

This procedure uses the oc-mirror plugin v2; the oc-mirror plugin v1 is now deprecated. For more information, see [Changes from oc-mirror plugin v1 to v2](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/oc-mirror-migration-v1-to-v2#oc-mirror-migration-differences_oc-mirror-migration-v1-to-v2) in the OpenShift documentation.

**Procedure**

1. Create a mirror registry. See [Creating a mirror registry with mirror registry for Red Hat OpenShift](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/installing-mirroring-creating-registry) in the OpenShift Container Platform documentation.
2. To mirror registry images, install the `oc-mirror` OpenShift CLI plugin v2 on your mirroring machine running Linux. See [Installing the oc-mirror OpenShift CLI plugin](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/about-installing-oc-mirror-v2#installation-oc-mirror-installing-plugin_about-installing-oc-mirror-v2) in the OpenShift Container Platform documentation.

   Important

   The oc-mirror plugin v1 is deprecated. Red Hat recommends that you use the oc-mirror plugin v2 for continued support and improvements.
3. Create a container image registry credentials file that allows mirroring images from Red Hat to your mirror. See [Configuring credentials that allow images to be mirrored](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/about-installing-oc-mirror-v2#installation-adding-registry-pull-secret_about-installing-oc-mirror-v2) in the OpenShift Container Platform documentation.
4. Open the example image set configuration file (`rhoai-<version>.md`) from the [disconnected installer helper](https://github.com/red-hat-data-services/rhoai-disconnected-install-helper/tree/main) repository and examine its contents.

   The disconnected installer helper file includes a list of **Additional images** required to install OpenShift AI in a disconnected environment, as well as a list of older **Unsupported images** provided for reference only. These older images are no longer maintained by Red Hat but are included for convenience, such as when importing older resources or maintaining compatibility with previous environments.
5. Using the example image set configuration file, create a file called `imageset-config.yaml` and populate it with values suitable for the image set configuration in your deployment.

   * To view a list of the available OpenShift versions, run the following command. This might take several minutes. If the command returns errors, repeat the steps in [Configuring credentials that allow images to be mirrored](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/about-installing-oc-mirror-v2#installation-adding-registry-pull-secret_about-installing-oc-mirror-v2).

     ```
     oc-mirror list operators
     ```
   * To see the available channels for a package in a specific version of OpenShift Container Platform (for example, 4.18), run the following command:

     ```
     oc-mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.18 --package=<package_name>
     ```
   * For information about subscription update channels, see [Understanding update channels](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/understanding-update-channels_install).

     Important

     The example image set configurations are for demonstration purposes only and might need further alterations depending on your deployment.

     To identify the attributes most suitable for your deployment, see [Image set configuration parameters](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/installing-mirroring-disconnected#oc-mirror-imageset-config-params_installing-mirroring-disconnected) and [Image set configuration examples](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/disconnected_environments/installing-mirroring-disconnected#oc-mirror-image-set-examples_installing-mirroring-disconnected) in the OpenShift Container Platform documentation.

     The list of **Unsupported images** in the helper file is provided for reference only and should not be included in your mirrored image set unless you have a specific need to import older resources or maintain compatibility with previous environments.

     **Example imageset-config.yaml**

     ```
     kind: ImageSetConfiguration
     apiVersion: mirror.openshift.io/v1alpha2
     mirror:
       operators:
         - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.19
           packages:
             - name: rhods-operator
               channels:
                 - name: stable
                   minVersion: 2.25.0
                   maxVersion: 2.25.0
             - name: <additional_operator_name>
               channels:
                 - name: stable
       additionalImages:
         - name: <additional_image_name>
     ```
6. Download the specified image set configuration to a local file on your mirroring machine:

   * Replace `<mirror_rhoai>` with the target directory where you want to output the image set file.
   * The target directory path must start with `file://`.
   * The download might take several minutes.

     ```
     $ oc mirror -c imageset-config.yaml file://<mirror_rhoai> --v2
     ```

     Tip

     If the `tls: failed to verify certificate: x509: certificate signed by unknown authority` error is returned and you want to ignore it, set `skipTLS` to `true` in your image set configuration file and run the command again.
7. Verify that the image set `.tar` files were created:

   ```
   $ ls <mirror_rhoai>
   ```

   **Example output**

   ```
   mirror_000001.tar, mirror_000002.tar
   ```

   If an `archiveSize` value was specified in the image set configuration file, the image set might be separated into multiple `.tar` files.
8. Optional: Verify that total size of the image set `.tar` files is around 75 GB:

   ```
   $ du -h --max-depth=1 ./<mirror_rhoai>/
   ```

   If the total size of the image set is significantly less than 75 GB, run the `oc mirror` command again.
9. Upload the contents of the generated image set to your target mirror registry:

   * Replace `<mirror_rhoai>` with the directory that contains your image set `.tar` files.
   * Replace `<registry.example.com:5000>` with your mirror registry.

     ```
     $ oc mirror -c imageset-config.yaml --from file://<mirror_rhoai> docker://<registry.example.com:5000> --v2
     ```

     Tip

     If the `tls: failed to verify certificate: x509: certificate signed by unknown authority` error is returned and you want to ignore it, run the following command:

     ```
     $ oc mirror --dest-tls-verify false --from=./<mirror_rhoai> docker://<registry.example.com:5000> --v2
     ```
10. Log in to your target OpenShift cluster using the OpenShift CLI as a user with the `cluster-admin` role.
11. Verify that the YAML files are present for the `ImageDigestMirrorSet` and `CatalogSource` resources:

    * Replace `<mirror_rhoai>` with the directory that contains your image set `.tar` files.

      ```
      $ ls <mirror_rhoai>/working-dir/cluster-resources/
      ```

      **Example output**

      ```
      cs-redhat-operator-index.yaml
      idms-oc-mirror.yaml
      ```
12. Install the generated resources into the cluster:

    * Replace `<oc_mirror_workspace_path>` with the path to your oc mirror workspace.

      ```
      $ oc apply -f <oc_mirror_workspace_path>/working-dir/cluster-resources
      ```

**Verification**

* Verify that the `CatalogSource` and pod were created successfully:

  ```
  $ oc get catalogsource,pod -n openshift-marketplace
  ```

  This should return at least one catalog and two pods.
* Check that the Red Hat OpenShift AI Operator exists in the OperatorHub:

  1. Log in to the OpenShift web console.
  2. Click **Operators** → **OperatorHub**.

     The **OperatorHub** page opens.
  3. Confirm that the Red Hat OpenShift AI Operator is shown.
* If you mirrored additional operators, check that those operators exist in the OperatorHub.

### [3.3. Configuring custom namespaces](#configuring-custom-namespaces) Copy linkLink copied to clipboard!

By default, OpenShift AI uses the following predefined namespaces:

* `redhat-ods-operator` contains the Red Hat OpenShift AI Operator
* `redhat-ods-applications` includes the dashboard and other required components of OpenShift AI
* `rhods-notebooks` is where basic workbenches are deployed by default

If needed, you can define custom namespaces to use instead of the predefined ones before installing OpenShift AI. This flexibility supports environments with naming policies or conventions and allows cluster administrators to control where components such as workbenches are deployed.

Namespaces created by OpenShift AI typically include `openshift` or `redhat` in their name. Do not rename these system namespaces because they are required for OpenShift AI to function properly.

**Prerequisites**

* You have access to an OpenShift AI cluster with cluster administrator privileges.
* You have installed the OpenShift CLI (`oc`) as described in the appropriate documentation for your cluster:

  + [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/cli_tools/openshift-cli-oc#installing-openshift-cli) for OpenShift Container Platform
  + [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cli_tools/openshift-cli-oc#installing-openshift-cli) for Red Hat OpenShift Service on AWS
* You have not yet installed the Red Hat OpenShift AI Operator.

**Procedure**

1. In a terminal window, if you are not already logged in to your OpenShift cluster as a cluster administrator, log in to the OpenShift CLI (`oc`) as shown in the following example:

   ```
   oc login <openshift_cluster_url> -u <admin_username> -p <password>
   ```
2. Optional: To configure a custom operator namespace:

   1. Create a namespace YAML file named `operator-namespace.yaml`.

      ```
      apiVersion: v1
      kind: Namespace
      metadata:
        name: <operator-namespace>
      ```

      1

      [1](#CO1-1)
      :   Defines the operator namespace.
   2. Create the namespace in your OpenShift cluster.

      ```
      $ oc create -f operator-namespace.yaml
      ```

      You see output similar to the following:

      ```
      namespace/<operator-namespace> created
      ```
   3. When you install the Red Hat OpenShift AI Operator, use this namespace instead of `redhat-ods-operator`.
3. Optional: To configure a custom applications namespace:

   1. Create a namespace YAML file named `applications-namespace.yaml`.

      ```
      apiVersion: v1
      kind: Namespace
      metadata:
        name: <applications-namespace>
      ```

      1

      ```
        labels:
          opendatahub.io/application-namespace: 'true'
      ```

      2

      [1](#CO2-1)
      :   Defines the applications namespace.

      [2](#CO2-2)
      :   Adds the required label.
   2. Create the namespace in your OpenShift cluster.

      ```
      $ oc create -f applications-namespace.yaml
      ```

      You see output similar to the following:

      ```
      namespace/<applications-namespace> created
      ```
4. Optional: To configure a custom workbench namespace:

   1. Create a namespace YAML file named `workbench-namespace.yaml`.

      ```
      apiVersion: v1
      kind: Namespace
      metadata:
        name: <workbench-namespace>
      ```

      1

      [1](#CO3-1)
      :   Defines the workbench namespace.
   2. Create the namespace in your OpenShift cluster.

      ```
      $ oc create -f workbench-namespace.yaml
      ```

      You see output similar to the following:

      ```
      namespace/<workbench-namespace> created
      ```
   3. When you install the Red Hat OpenShift AI components, specify this namespace for the `spec.workbenches.workbenchNamespace` field. You cannot change the default workbench namespace after you have installed the Red Hat OpenShift AI Operator.

**Next step**

[Installing the Red Hat OpenShift AI Operator](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-the-openshift-data-science-operator_operator-install)

### [3.4. Installing the Red Hat OpenShift AI Operator](#installing-the-openshift-data-science-operator_operator-install) Copy linkLink copied to clipboard!

This section shows how to install the Red Hat OpenShift AI Operator on your OpenShift cluster using the command-line interface (CLI) and the OpenShift web console.

Note

If you want to upgrade from a previous version of OpenShift AI rather than performing a new installation, see [Upgrading OpenShift AI in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/upgrading_openshift_ai_self-managed_in_a_disconnected_environment/).

Note

If your OpenShift cluster uses a proxy to access the Internet, you can configure the proxy settings for the Red Hat OpenShift AI Operator. See [Overriding proxy settings of an Operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/operators/administrator-tasks#olm-overriding-proxy-settings_olm-configuring-proxy-support) for more information.

#### [3.4.1. Installing the Red Hat OpenShift AI Operator by using the CLI](#installing-openshift-ai-operator-using-cli_operator-install) Copy linkLink copied to clipboard!

The following procedure shows how to use the OpenShift CLI (`oc`) to install the Red Hat OpenShift AI Operator on your OpenShift cluster. You must install the Operator before you can install OpenShift AI components on the cluster.

**Prerequisites**

* You have a running OpenShift cluster, version 4.16 or greater, configured with a default storage class that can be dynamically provisioned.
* You have cluster administrator privileges for your OpenShift cluster.
* You have installed the OpenShift CLI (`oc`) as described in the appropriate documentation for your cluster:

  + [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/cli_tools/openshift-cli-oc#installing-openshift-cli) for OpenShift Container Platform
  + [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cli_tools/openshift-cli-oc#installing-openshift-cli) for Red Hat OpenShift Service on AWS
* If you are using custom namespaces, you have created and labeled them as required.

  Note

  The example commands in this procedure use the predefined operator namespace. If you are using a custom operator namespace, replace `redhat-ods-operator` with your namespace.
* You have mirrored the required container images to a private registry. See [Mirroring images to a private registry for a disconnected installation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#mirroring-images-to-a-private-registry-for-a-disconnected-installation_install).

**Procedure**

1. Open a new terminal window.
2. Follow these steps to log in to your OpenShift cluster as a cluster administrator:

   1. In the upper-right corner of the OpenShift web console, click your user name and select **Copy login command**.
   2. After you have logged in, click **Display token**.
   3. Copy the **Log in with this token** command and paste it in your terminal.

      ```
      $ oc login --token=<token> --server=<openshift_cluster_url>
      ```
3. Create a namespace for installation of the Operator by performing the following actions:

   Note

   If you have already created a custom namespace for the Operator, you can skip this step.

   1. Create a namespace YAML file named `rhods-operator-namespace.yaml`.

      ```
      apiVersion: v1
      kind: Namespace
      metadata:
        name: redhat-ods-operator
      ```

      1

      [1](#CO4-1)
      :   Defines the operator namespace.
   2. Create the namespace in your OpenShift cluster.

      ```
      $ oc create -f rhods-operator-namespace.yaml
      ```

      You see output similar to the following:

      ```
      namespace/redhat-ods-operator created
      ```
4. Create an operator group for installation of the Operator by performing the following actions:

   1. Create an `OperatorGroup` object custom resource (CR) file, for example, `rhods-operator-group.yaml`.

      ```
      apiVersion: operators.coreos.com/v1
      kind: OperatorGroup
      metadata:
        name: rhods-operator
        namespace: redhat-ods-operator
      ```

      1

      [1](#CO5-1)
      :   Defines the operator namespace.
   2. Create the `OperatorGroup` object in your OpenShift cluster.

      ```
      $ oc create -f rhods-operator-group.yaml
      ```

      You see output similar to the following:

      ```
      operatorgroup.operators.coreos.com/rhods-operator created
      ```
5. Create a subscription for installation of the Operator by performing the following actions:

   1. Create a `Subscription` object CR file, for example, `rhods-operator-subscription.yaml`.

      ```
      apiVersion: operators.coreos.com/v1alpha1
      kind: Subscription
      metadata:
        name: rhods-operator
        namespace: redhat-ods-operator
      ```

      1

      ```
      spec:
        name: rhods-operator
        channel: <channel>
      ```

      2

      ```
        source: cs-redhat-operator-index
        sourceNamespace: openshift-marketplace
        startingCSV: rhods-operator.x.y.z
      ```

      3

      [1](#CO6-1)
      :   Defines the operator namespace.

      [2](#CO6-2)
      :   Sets the update channel. You must specify a value of `fast`, `stable`, `stable-x.y` `eus-x.y`, or `alpha`. For more information, see [Understanding update channels](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/understanding-update-channels_install).

      [3](#CO6-3)
      :   Optional: Sets the operator version. If you do not specify a value, the subscription defaults to the latest operator version. For more information, see the [Red Hat OpenShift AI Self-Managed Life Cycle](https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle) Knowledgebase article.
   2. Create the `Subscription` object in your OpenShift cluster to install the Operator.

      ```
      $ oc create -f rhods-operator-subscription.yaml
      ```

      You see output similar to the following:

      ```
      subscription.operators.coreos.com/rhods-operator created
      ```

**Verification**

* In the OpenShift web console, click **Operators** → **Installed Operators** and confirm that the Red Hat OpenShift AI Operator shows one of the following statuses:

  + **Installing** - installation is in progress; wait for this to change to **Succeeded**. This might take several minutes.
  + **Succeeded** - installation is successful.

**Next step**

* [Installing and managing Red Hat OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-and-managing-openshift-ai-components_component-install)

#### [3.4.2. Installing the Red Hat OpenShift AI Operator by using the web console](#installing-openshift-ai-operator-using-web-console_operator-install) Copy linkLink copied to clipboard!

The following procedure shows how to use the OpenShift web console to install the Red Hat OpenShift AI Operator on your cluster. You must install the Operator before you can install OpenShift AI components on the cluster.

**Prerequisites**

* You have a running OpenShift cluster, version 4.16 or greater, configured with a default storage class that can be dynamically provisioned.
* You have cluster administrator privileges for your OpenShift cluster.
* If you are using custom namespaces, you have created and labeled them as required.
* You have mirrored the required container images to a private registry. See [Mirroring images to a private registry for a disconnected installation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#mirroring-images-to-a-private-registry-for-a-disconnected-installation_install).

**Procedure**

1. Log in to the OpenShift web console as a cluster administrator.
2. In the web console, click **Operators** → **OperatorHub**.
3. On the **OperatorHub** page, locate the Red Hat OpenShift AI Operator by scrolling through the available Operators or by typing *Red Hat OpenShift AI* into the **Filter by keyword** box.
4. Click the **Red Hat OpenShift AI** tile. The **Red Hat OpenShift AI** information pane opens.
5. Select a **Channel**. For information about subscription update channels, see [Understanding update channels](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/understanding-update-channels_install).
6. Select a **Version**.
7. Click **Install**. The **Install Operator** page opens.
8. Review or change the selected channel and version as needed.
9. For **Installation mode**, note that the only available value is **All namespaces on the cluster (default)**. This installation mode makes the Operator available to all namespaces in the cluster.
10. For **Installed Namespace**, choose one of the following options:

    * To use the predefined operator namespace, select the **Operator recommended Namespace: redhat-ods-operator** option.
    * To use the custom operator namespace that you created, select the **Select a Namespace** option, and then select the namespace from the drop-down list.
11. For **Update approval**, select one of the following update strategies:

    * **Automatic**: Your environment attempts to install new updates when they are available based on the content of your mirror.
    * **Manual**: A cluster administrator must approve any new updates before installation begins.

      Important

      By default, the Red Hat OpenShift AI Operator follows a sequential update process. This means that if there are several versions between the current version and the target version, Operator Lifecycle Manager (OLM) upgrades the Operator to each of the intermediate versions before it upgrades it to the final, target version.

      If you configure automatic upgrades, OLM automatically upgrades the Operator to the *latest* available version. If you configure manual upgrades, a cluster administrator must manually approve each sequential update between the current version and the final, target version.

      For information about supported versions, see the [Red Hat OpenShift AI Life Cycle](https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle) Knowledgebase article.
12. Click **Install**.

    The **Installing Operators** pane appears. When the installation finishes, a checkmark appears next to the Operator name.

**Verification**

* In the OpenShift web console, click **Operators** → **Installed Operators** and confirm that the Red Hat OpenShift AI Operator shows one of the following statuses:

  + **Installing** - installation is in progress; wait for this to change to **Succeeded**. This might take several minutes.
  + **Succeeded** - installation is successful.

**Next step**

* [Installing and managing Red Hat OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-and-managing-openshift-ai-components_component-install)

### [3.5. Installing and managing Red Hat OpenShift AI components](#installing-and-managing-openshift-ai-components_component-install) Copy linkLink copied to clipboard!

You can use the OpenShift command-line interface (CLI) or OpenShift web console to install and manage components of Red Hat OpenShift AI on your OpenShift cluster.

#### [3.5.1. Installing Red Hat OpenShift AI components by using the CLI](#installing-openshift-ai-components-using-cli_component-install) Copy linkLink copied to clipboard!

To install Red Hat OpenShift AI components by using the OpenShift CLI (`oc`), you must create and configure a `DataScienceCluster` object.

Important

The following procedure describes how to create and configure a `DataScienceCluster` object to install Red Hat OpenShift AI components as part of a *new* installation.

* For information about changing the installation status of OpenShift AI components *after* installation, see [Updating the installation status of Red Hat OpenShift AI components by using the web console](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#updating-installation-status-of-openshift-ai-components-using-web-console_component-install).
* For information about *upgrading* OpenShift AI, see [Upgrading OpenShift AI Self-Managed in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/upgrading_openshift_ai_self-managed_in_a_disconnected_environment/index).

**Prerequisites**

* The Red Hat OpenShift AI Operator is installed on your OpenShift cluster. See [Installing the Red Hat OpenShift AI Operator](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-the-openshift-data-science-operator_operator-install).
* You have cluster administrator privileges for your OpenShift cluster.
* You have installed the OpenShift CLI (`oc`) as described in the appropriate documentation for your cluster:

  + [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/cli_tools/openshift-cli-oc#installing-openshift-cli) for OpenShift Container Platform
  + [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/red_hat_openshift_service_on_aws/4/html/cli_tools/openshift-cli-oc#installing-openshift-cli) for Red Hat OpenShift Service on AWS
* If you are using custom namespaces, you have created the namespaces.

**Procedure**

1. Open a new terminal window.
2. Follow these steps to log in to your OpenShift cluster as a cluster administrator:

   1. In the upper-right corner of the OpenShift web console, click your user name and select **Copy login command**.
   2. After you have logged in, click **Display token**.
   3. Copy the **Log in with this token** command and paste it in your terminal.

      ```
      $ oc login --token=<token> --server=<openshift_cluster_url>
      ```
3. Create a `DataScienceCluster` object custom resource (CR) file, for example, `rhods-operator-dsc.yaml`.

   ```
   apiVersion: datasciencecluster.opendatahub.io/v1
   kind: DataScienceCluster
   metadata:
     name: default-dsc
   spec:
     components:
       codeflare:
         managementState: Removed
       dashboard:
         managementState: Removed
       datasciencepipelines:
         argoWorkflowsControllers:
           managementState: Removed
   ```

   1

   ```
         managementState: Removed
       feastoperator:
         managementState: Removed
       kserve:
         managementState: Removed
   ```

   2

   ```

   ```

   3

   ```
       kueue:
         defaultClusterQueueName: default
         defaultLocalQueueName: default
         managementState: Removed
       llamastackoperator:
         managementState: Removed
       modelmeshserving:
         managementState: Removed
       modelregistry:
         managementState: Removed
         registriesNamespace: {mr-default-namespace}
       ray:
         managementState: Removed
       trainingoperator:
         managementState: Removed
       trustyai:
         managementState: Removed
       workbenches:
         managementState: Removed
         workbenchNamespace: {workbench-default-namespace}
   ```

   4

   [1](#CO7-1)
   :   To use your own Argo Workflows instance with the `datasciencepipelines` component, set `argoWorkflowsControllers.managementState` to `Removed`. This allows you to integrate with a managed Argo Workflows installation already on your OpenShift cluster and avoid conflicts with the embedded controller. See *Configuring pipelines with your own Argo Workflows instance*.

   [2](#CO7-2)
   :   To fully install the KServe component, which is used by the single-model serving platform to serve large models, you must install Operators for Red Hat OpenShift Service Mesh and Red Hat OpenShift Serverless and perform additional configuration. See [Installing the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install).

   [3](#CO7-3)
   :   If you have *not* enabled the KServe component (that is, you set the value of the `managementState` field to `Removed`), you must also disable the dependent Service Mesh component to avoid errors. See [Disabling KServe dependencies](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install#disabling-kserve-dependencies_component-install).

   [4](#CO7-4)
   :   To use the predefined workbench namespace, set this value to `rhods-notebooks` or omit this line. To use a custom workbench namespace, set this value to your namespace.
4. In the `spec.components` section of the CR, for each OpenShift AI component shown, set the value of the `managementState` field to either `Managed` or `Removed`. These values are defined as follows:

   Managed
   :   The Operator actively manages the component, installs it, and tries to keep it active. The Operator will upgrade the component only if it is safe to do so.

   Removed
   :   The Operator actively manages the component but does not install it. If the component is already installed, the Operator will try to remove it.

   Important

   * To learn how to fully install the KServe component, which is used by the single-model serving platform to serve large models, see [Installing the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install).
   * If you have *not* enabled the KServe component (that is, you set the value of the `managementState` field to `Removed`), you must also disable the dependent Service Mesh component to avoid errors. See [Disabling KServe dependencies](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install#disabling-kserve-dependencies_component-install).
   * To learn how to install the distributed workloads components, see [Installing the distributed workloads components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-distributed-workloads-components_install).
   * To learn how to run distributed workloads in a disconnected environment, see [Running distributed data science workloads in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_distributed_workloads/index#running-distributed-data-science-workloads-disconnected-env_distributed-workloads).
5. Create the `DataScienceCluster` object in your OpenShift cluster to install the specified OpenShift AI components.

   ```
   $ oc create -f rhods-operator-dsc.yaml
   ```

   You see output similar to the following:

   ```
   datasciencecluster.datasciencecluster.opendatahub.io/default created
   ```

**Verification**

1. Confirm that there is at least one running pod for each component:

   1. In the OpenShift web console, click **Workloads** → **Pods**.
   2. In the **Project** list at the top of the page, select `redhat-ods-applications`.
   3. In the applications namespace, confirm that there are one or more running pods for each of the OpenShift AI components that you installed.
2. Confirm the status of all installed components:

   1. In the OpenShift web console, click **Operators** → **Installed Operators**.
   2. Click the **Red Hat OpenShift AI** Operator.
   3. Click the **Data Science Cluster** tab.
   4. For the `DataScienceCluster` object called `default-dsc`, verify that the status is `Phase: Ready`.

      Note

      When you edit the `spec.components` section to change the installation status of a component, the `default-dsc` status also changes. During the initial installation, it might take a few minutes for the status phase to change from `Progressing` to `Ready`. You can access the OpenShift AI dashboard before the `default-dsc` status phase is `Ready`, but all components might not be ready.
   5. Click the `default-dsc` link to display the data science cluster details.
   6. Select the **YAML** tab.
   7. In the `status.installedComponents` section, confirm that the components you installed have a status value of `true`.

      Note

      If a component shows with the `component-name: {}` format in the `spec.components` section of the CR, the component is not installed.
3. In the OpenShift AI dashboard, users can view the list of the installed OpenShift AI components, their corresponding source (upstream) components, and the versions of the installed components, as described in [Viewing installed OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#viewing-installed-components_component-install).

#### [3.5.2. Installing Red Hat OpenShift AI components by using the web console](#installing-openshift-ai-components-using-web-console_component-install) Copy linkLink copied to clipboard!

To install Red Hat OpenShift AI components by using the OpenShift web console, you must create and configure a `DataScienceCluster` object.

Important

The following procedure describes how to create and configure a `DataScienceCluster` object to install Red Hat OpenShift AI components as part of a *new* installation.

* For information about changing the installation status of OpenShift AI components *after* installation, see [Updating the installation status of Red Hat OpenShift AI components by using the web console](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#updating-installation-status-of-openshift-ai-components-using-web-console_component-install).
* For information about *upgrading* OpenShift AI, see [Upgrading OpenShift AI Self-Managed in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/upgrading_openshift_ai_self-managed_in_a_disconnected_environment/index).

**Prerequisites**

* The Red Hat OpenShift AI Operator is installed on your OpenShift cluster. See [Installing the Red Hat OpenShift AI Operator](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-the-openshift-data-science-operator_operator-install).
* You have cluster administrator privileges for your OpenShift cluster.
* If you are using custom namespaces, you have created the namespaces.

**Procedure**

1. Log in to the OpenShift web console as a cluster administrator.
2. In the web console, click **Operators** → **Installed Operators** and then click the **Red Hat OpenShift AI** Operator.
3. Click the **Data Science Cluster** tab.
4. Click **Create DataScienceCluster**.
5. For **Configure via**, select **YAML view**.

   An embedded YAML editor opens showing a default custom resource (CR) for the `DataScienceCluster` object, similar to the following example:

   ```
   apiVersion: datasciencecluster.opendatahub.io/v1
   kind: DataScienceCluster
   metadata:
     name: default-dsc
   spec:
     components:
       codeflare:
         managementState: Removed
       dashboard:
         managementState: Removed
       datasciencepipelines:
         argoWorkflowsControllers:
           managementState: Removed
   ```

   1

   ```
         managementState: Removed
       feastoperator:
         managementState: Removed
       kserve:
         managementState: Removed
   ```

   2

   ```

   ```

   3

   ```
       kueue:
         defaultClusterQueueName: default
         defaultLocalQueueName: default
         managementState: Removed
       llamastackoperator:
         managementState: Removed
       modelmeshserving:
         managementState: Removed
       modelregistry:
         managementState: Removed
         registriesNamespace: {mr-default-namespace}
       ray:
         managementState: Removed
       trainingoperator:
         managementState: Removed
       trustyai:
         managementState: Removed
       workbenches:
         managementState: Removed
         workbenchNamespace: {workbench-default-namespace}
   ```

   4

   [1](#CO8-1)
   :   To use your own Argo Workflows instance with the `datasciencepipelines` component, set `argoWorkflowsControllers.managementState` to `Removed`. This allows you to integrate with a managed Argo Workflows installation already on your OpenShift cluster and avoid conflicts with the embedded controller. See *Configuring pipelines with your own Argo Workflows instance*.

   [2](#CO8-2)
   :   To fully install the KServe component, which is used by the single-model serving platform to serve large models, you must install Operators for Red Hat OpenShift Service Mesh and Red Hat OpenShift Serverless and perform additional configuration. See [Installing the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install).

   [3](#CO8-3)
   :   If you have *not* enabled the KServe component (that is, you set the value of the `managementState` field to `Removed`), you must also disable the dependent Service Mesh component to avoid errors. See [Disabling KServe dependencies](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install#disabling-kserve-dependencies_component-install).

   [4](#CO8-4)
   :   To use the predefined workbench namespace, set this value to `rhods-notebooks` or omit this line. To use a custom workbench namespace, set this value to your namespace.
6. In the `spec.components` section of the CR, for each OpenShift AI component shown, set the value of the `managementState` field to either `Managed` or `Removed`. These values are defined as follows:

   Managed
   :   The Operator actively manages the component, installs it, and tries to keep it active. The Operator will upgrade the component only if it is safe to do so.

   Removed
   :   The Operator actively manages the component but does not install it. If the component is already installed, the Operator will try to remove it.

   Important

   * To learn how to fully install the KServe component, which is used by the single-model serving platform to serve large models, see [Installing the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install).
   * If you have *not* enabled the KServe component (that is, you set the value of the `managementState` field to `Removed`), you must also disable the dependent Service Mesh component to avoid errors. See [Disabling KServe dependencies](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install#disabling-kserve-dependencies_component-install).
   * To learn how to install the distributed workloads components, see [Installing the distributed workloads components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-distributed-workloads-components_install).
   * To learn how to run distributed workloads in a disconnected environment, see [Running distributed data science workloads in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_distributed_workloads/index#running-distributed-data-science-workloads-disconnected-env_distributed-workloads).
7. Click **Create**.

**Verification**

1. Confirm the status of all installed components:

   1. In the OpenShift web console, click **Operators** → **Installed Operators**.
   2. Click the **Red Hat OpenShift AI** Operator.
   3. Click the **Data Science Cluster** tab.
   4. For the `DataScienceCluster` object called `default-dsc`, verify that the status is `Phase: Ready`.

      Note

      When you edit the `spec.components` section to change the installation status of a component, the `default-dsc` status also changes. During the initial installation, it might take a few minutes for the status phase to change from `Progressing` to `Ready`. You can access the OpenShift AI dashboard before the `default-dsc` status phase is `Ready`, but all components might not be ready.
   5. Click the `default-dsc` link to display the data science cluster details.
   6. Select the **YAML** tab.
   7. In the `status.installedComponents` section, confirm that the components you installed have a status value of `true`.

      Note

      If a component shows with the `component-name: {}` format in the `spec.components` section of the CR, the component is not installed.
2. Confirm that there is at least one running pod for each component:

   1. In the OpenShift web console, click **Workloads** → **Pods**.
   2. In the **Project** list at the top of the page, select `redhat-ods-applications` or your custom applications namespace.
   3. In the applications namespace, confirm that there are one or more running pods for each of the OpenShift AI components that you installed.
3. In the OpenShift AI dashboard, users can view the list of the installed OpenShift AI components, their corresponding source (upstream) components, and the versions of the installed components, as described in [Viewing installed OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#viewing-installed-components_component-install).

#### [3.5.3. Updating the installation status of Red Hat OpenShift AI components by using the web console](#updating-installation-status-of-openshift-ai-components-using-web-console_component-install) Copy linkLink copied to clipboard!

You can use the OpenShift web console to update the installation status of components of Red Hat OpenShift AI on your OpenShift cluster.

Important

If you upgraded OpenShift AI, the upgrade process automatically used the values of the previous version’s `DataScienceCluster` object. New components are not automatically added to the `DataScienceCluster` object.

After upgrading OpenShift AI:

* Inspect the default `DataScienceCluster` object to check and optionally update the `managementState` status of the existing components.
* Add any new components to the `DataScienceCluster` object.

**Prerequisites**

* The Red Hat OpenShift AI Operator is [installed](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-the-openshift-data-science-operator_operator-install) on your OpenShift cluster.
* You have cluster administrator privileges for your OpenShift cluster.

**Procedure**

1. Log in to the OpenShift web console as a cluster administrator.
2. In the web console, click **Operators** → **Installed Operators** and then click the **Red Hat OpenShift AI** Operator.
3. Click the **Data Science Cluster** tab.
4. On the **DataScienceClusters** page, click the `default-dsc` object.
5. Click the **YAML** tab.

   An embedded YAML editor opens showing the default custom resource (CR) for the `DataScienceCluster` object, similar to the following example:

   ```
   apiVersion: datasciencecluster.opendatahub.io/v1
   kind: DataScienceCluster
   metadata:
     name: default-dsc
   spec:
     components:
       codeflare:
         managementState: Removed
       dashboard:
         managementState: Removed
       datasciencepipelines:
         managementState: Removed
       kserve:
         managementState: Removed
       kueue:
         managementState: Removed
       llamastackoperator:
         managementState: Removed
       modelmeshserving:
         managementState: Removed
       ray:
         managementState: Removed
       trainingoperator:
         managementState: Removed
       trustyai:
         managementState: Removed
       workbenches:
         managementState: Removed
         workbenchNamespace: rhods-notebooks
   ```
6. In the `spec.components` section of the CR, for each OpenShift AI component shown, set the value of the `managementState` field to either `Managed` or `Removed`. These values are defined as follows:

   Managed
   :   The Operator actively manages the component, installs it, and tries to keep it active. The Operator will upgrade the component only if it is safe to do so.

   Removed
   :   The Operator actively manages the component but does not install it. If the component is already installed, the Operator will try to remove it.

   Important

   * To learn how to install the KServe component, which is used by the single-model serving platform to serve large models, see [Installing the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install).
   * If you have *not* enabled the KServe component (that is, you set the value of the `managementState` field to `Removed`), you must also disable the dependent Service Mesh component to avoid errors. See [Disabling KServe dependencies](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-single-model-serving-platform_component-install#disabling-kserve-dependencies_component-install).
   * To learn how to install the distributed workloads feature, see [Installing the distributed workloads components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/installing-the-distributed-workloads-components_install).
   * To learn how to run distributed workloads in a disconnected environment, see [Running distributed data science workloads in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/working_with_distributed_workloads/index#running-distributed-data-science-workloads-disconnected-env_distributed-workloads).
7. Click **Save**.

   For any components that you updated, OpenShift AI initiates a rollout that affects all pods to use the updated image.
8. If you are upgrading from OpenShift AI 2.19 or earlier, upgrade the Authorino Operator to the `stable` update channel, version 1.2.1 or later.

   Important

   If you are upgrading the Authorino Operator to the `stable` update channel, version 1.2.1 or later in a disconnected environment, use the following upgrade procedure described in the release notes: [RHOAIENG-24786 - Upgrading the Authorino Operator from Technical Preview to Stable fails in disconnected environments](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html-single/release_notes/index#known-issues_RHOAIENG-2478_relnotes). Otherwise, the upgrade can fail.

**Verification**

1. Confirm that there is at least one running pod for each component:

   1. In the OpenShift web console, click **Workloads** → **Pods**.
   2. In the **Project** list at the top of the page, select `redhat-ods-applications` or your custom applications namespace.
   3. In the applications namespace, confirm that there are one or more running pods for each of the OpenShift AI components that you installed.
2. Confirm the status of all installed components:

   1. In the OpenShift web console, click **Operators** → **Installed Operators**.
   2. Click the **Red Hat OpenShift AI** Operator.
   3. Click the **Data Science Cluster** tab and select the `DataScienceCluster` object called `default-dsc`.
   4. Select the **YAML** tab.
   5. In the `status.installedComponents` section, confirm that the components you installed have a status value of `true`.

      Note

      If a component shows with the `component-name: {}` format in the `spec.components` section of the CR, the component is not installed.
3. In the OpenShift AI dashboard, users can view the list of the installed OpenShift AI components, their corresponding source (upstream) components, and the versions of the installed components, as described in [Viewing installed OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#viewing-installed-components_component-install).

#### [3.5.4. Viewing installed OpenShift AI components](#viewing-installed-components_component-install) Copy linkLink copied to clipboard!

In the Red Hat OpenShift AI dashboard, you can view a list of the installed OpenShift AI components, their corresponding source (upstream) components, and the versions of the installed components.

**Prerequisites**

* OpenShift AI is installed in your OpenShift cluster.

**Procedure**

1. Log in to the OpenShift AI dashboard.
2. In the top navigation bar, click the help icon (
   ) and then select **About**.

**Verification**

The **About** page shows a list of the installed OpenShift AI components along with their corresponding upstream components and upstream component versions.

**Additional resources**

* [Installing and managing Red Hat OpenShift AI components](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install#installing-and-managing-openshift-ai-components_component-install).

## [Chapter 4. Configuring pipelines with your own Argo Workflows instance](#configuring-pipelines-with-your-own-argo-workflows-instance_install) Copy linkLink copied to clipboard!

You can configure OpenShift AI to use an existing Argo Workflows instance instead of the embedded one included with Data Science Pipelines. This configuration is useful if your OpenShift cluster already includes a managed Argo Workflows instance and you want to integrate it with OpenShift AI pipelines without conflicts. Disabling the embedded Argo Workflows controller allows cluster administrators to manage the lifecycles of OpenShift AI and Argo Workflows independently.

Note

You cannot enable both the embedded Argo Workflows instance and your own Argo Workflows instance on the same cluster.

**Prerequisites**

* You have cluster administrator privileges for your OpenShift cluster.
* You have installed Red Hat OpenShift AI.

**Procedure**

1. Log in to the OpenShift web console as a cluster administrator.
2. In the OpenShift console, click **Operators** → **Installed Operators**.
3. Search for the **Red Hat OpenShift AI** Operator, and then click the Operator name to open the Operator details page.
4. Click the **Data Science Cluster** tab.
5. Click the default instance name (for example, **default-dsc**) to open the instance details page.
6. Click the **YAML** tab to show the instance specifications.
7. Disable the embedded Argo Workflows controllers that are managed by the OpenShift AI Operator:

   1. In the `spec.components` section, set the value of the `managementState` field for the `datasciencepipelines` component to `Managed`.
   2. In the `spec.components.datasciencepipelines` section, set the value of the `managementState` field for `argoWorkflowsControllers` to `Removed`, as shown in the following example:

      **Example datasciencepipelines specification**

      ```
      # ...
      spec:
        components:
          datasciencepipelines:
            argoWorkflowsControllers:
              managementState: Removed
            managementState: Managed
      # ...
      ```
8. Click **Save** to apply your changes.
9. Install and configure a compatible version of Argo Workflows on your cluster. For compatible version information, see [Supported Configurations](https://access.redhat.com/articles/rhoai-supported-configs). For installation information, see the [Argo Workflows Installation documentation](https://argo-workflows.readthedocs.io/en/stable/installation/).

**Verification**

1. On the **Details** tab of the `DataScienceCluster` instance (for example, **default-dsc**), verify that `DataSciencePipelinesReady` has a **Status** of `True`.
2. Verify that the `ds-pipeline-workflow-controller` pod does not exist:

   1. Go to **Workloads** → **Pods**.
   2. Search for the `ds-pipeline-workflow-controller` pod.
   3. Verify that this pod does not exist. The absence of this pod confirms that the embedded Argo Workflows controller is disabled.

## [Chapter 5. Installing the distributed workloads components](#installing-the-distributed-workloads-components_install) Copy linkLink copied to clipboard!

To use the distributed workloads feature in OpenShift AI, you must install several components.

**Prerequisites**

* You have logged in to OpenShift with the `cluster-admin` role and you can access the data science cluster.
* You have installed Red Hat OpenShift AI.
* You have installed the Red Hat build of Kueue Operator on your OpenShift cluster, as described in the [Red Hat build of Kueue documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/ai_workloads/red-hat-build-of-kueue).
* You have sufficient resources. In addition to the minimum OpenShift AI resources described in [Installing and deploying OpenShift AI](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed/installing-and-deploying-openshift-ai_install) (for disconnected environments, see [Deploying OpenShift AI in a disconnected environment](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/deploying-openshift-ai-in-a-disconnected-environment_install)), you need 1.6 vCPU and 2 GiB memory to deploy the distributed workloads infrastructure.
* You have removed any previously installed instances of the CodeFlare Operator, as described in the Knowledgebase solution [How to migrate from a separately installed CodeFlare Operator in your data science cluster](https://access.redhat.com/solutions/7043796).
* If you want to use graphics processing units (GPUs), you have enabled GPU support in OpenShift AI. If you use NVIDIA GPUs, see [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/managing_openshift_ai/enabling-accelerators#enabling-nvidia-gpus_managing-rhoai). If you use AMD GPUs, see [AMD GPU integration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/managing_openshift_ai/enabling-accelerators#amd-gpu-integration_managing-rhoai).

  Note

  In OpenShift AI, Red Hat supports the use of accelerators within the same cluster only.

  Starting from Red Hat OpenShift AI 2.19, Red Hat supports remote direct memory access (RDMA) for NVIDIA GPUs only, enabling them to communicate directly with each other by using NVIDIA GPUDirect RDMA across either Ethernet or InfiniBand networks.
* If you want to use self-signed certificates, you have added them to a central Certificate Authority (CA) bundle as described in [Working with certificates](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed/working-with-certificates_certs) (for disconnected environments, see [Working with certificates](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/working-with-certificates_certs)). No additional configuration is necessary to use those certificates with distributed workloads. The centrally configured self-signed certificates are automatically available in the workload pods at the following mount points:

  + Cluster-wide CA bundle:

    ```
    /etc/pki/tls/certs/odh-trusted-ca-bundle.crt
    /etc/ssl/certs/odh-trusted-ca-bundle.crt
    ```
  + Custom CA bundle:

    ```
    /etc/pki/tls/certs/odh-ca-bundle.crt
    /etc/ssl/certs/odh-ca-bundle.crt
    ```

**Procedure**

1. In the OpenShift console, click **Operators** → **Installed Operators**.
2. Search for the **Red Hat OpenShift AI** Operator, and then click the Operator name to open the Operator details page.
3. Click the **Data Science Cluster** tab.
4. Click the default instance name (for example, **default-dsc**) to open the instance details page.
5. Click the **YAML** tab to show the instance specifications.
6. Enable the required distributed workloads components. In the `spec.components` section, set the `managementState` field correctly for the required components:

   * Set `kueue` to `Unmanaged` to allow the Red Hat build of Kueue Operator to manage Kueue.
   * If you want to use the CodeFlare framework to tune models, set `codeflare` and `ray` to `Managed`.
   * If you want to use the Kubeflow Training Operator to tune models, set `trainingoperator` to `Managed`.
   * The list of required components depends on whether the distributed workload is run from a pipeline or workbench or both, as shown in the following table.

   Expand

   Table 5.1. Components required for distributed workloads

   | Component | Pipelines only | Workbenches only | Pipelines and workbenches |
   | --- | --- | --- | --- |
   | `codeflare` | `Managed` | `Managed` | `Managed` |
   | `dashboard` | `Managed` | `Managed` | `Managed` |
   | `datasciencepipelines` | `Managed` | `Removed` | `Managed` |
   | `kueue` | `Unmanaged` | `Unmanaged` | `Unmanaged` |
   | `ray` | `Managed` | `Managed` | `Managed` |
   | `trainingoperator` | `Managed` | `Managed` | `Managed` |
   | `workbenches` | `Removed` | `Managed` | `Managed` |

   Show more
7. Click **Save**. After a short time, the components with a `Managed` state are ready.

**Verification**

Check the status of the **codeflare-operator-manager**, **kubeflow-training-operator**, **kuberay-operator**, **kueue-controller-manager**, and **openshift-kueue-operator** pods, as follows:

1. In the OpenShift console, click **Workloads** → **Deployments**.
2. In the **Search by name** field, enter the following search strings:

   * In the **redhat-ods-applications** project, search for **codeflare-operator-manager**, **kubeflow-training-operator**, and **kuberay-operator**.
   * In the **openshift-kueue-operator** project, search for **kueue-controller-manager** and **openshift-kueue-operator**.
3. In each case, check the status as follows:

   1. Click the deployment name to open the deployment details page.
   2. Click the **Pods** tab.
   3. Check the pod status.

      When the status of the pods is **Running**, the pods are ready to use.
   4. To see more information about each pod, click the pod name to open the pod details page, and then click the **Logs** tab.

**Next Step**

Configure the distributed workloads feature as described in [Managing distributed workloads](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/managing_openshift_ai/managing-distributed-workloads_managing-rhoai).

## [Chapter 6. Installing the single-model serving platform](#installing-the-single-model-serving-platform_component-install) Copy linkLink copied to clipboard!

### [6.1. About the single-model serving platform](#About-the-single-model-serving-platform_component-install) Copy linkLink copied to clipboard!

For deploying large models such as large language models (LLMs), OpenShift AI includes a single-model serving platform that is based on the [KServe](https://github.com/kserve/kserve) component. To install the single-model serving platform, the following components are required:

* [KServe](https://github.com/opendatahub-io/kserve): A Kubernetes custom resource definition (CRD) that orchestrates model serving for all types of models. KServe includes model-serving runtimes that implement the loading of given types of model servers. KServe also handles the lifecycle of the deployment object, storage access, and networking setup.
* [Red Hat OpenShift Serverless](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/serverless/about-serverless): A cloud-native development model that allows for serverless deployments of models. OpenShift Serverless is based on the open source [Knative](https://knative.dev/docs/) project.
* [Red Hat OpenShift Service Mesh](https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/service_mesh/service-mesh-2-x#ossm-understanding-service-mesh_ossm-architecture): A service mesh networking layer that manages traffic flows and enforces access policies. OpenShift Service Mesh is based on the open source [Istio](https://istio.io/) project.

  Note

  Currently, only OpenShift Service Mesh v2 is supported. For more information, see [Supported Configurations](https://access.redhat.com/articles/rhoai-supported-configs).

You can install the single-model serving platform manually or in an automated fashion:

Automated installation
:   If you have not already created a `ServiceMeshControlPlane` or `KNativeServing` resource on your OpenShift cluster, you can configure the Red Hat OpenShift AI Operator to install KServe and configure its dependencies. For more information, see [Configuring automated installation of KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#configuring-automated-installation-of-kserve_component-install).

Manual installation
:   If you have already created a `ServiceMeshControlPlane` or `KNativeServing` resource on your OpenShift cluster, you *cannot* configure the Red Hat OpenShift AI Operator to install KServe and configure its dependencies. In this situation, you must install KServe manually. For more information, see [Manually installing KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#manually-installing-kserve_component-install).

    Note

    You can run KServe in `Unmanaged` mode during manual installations of the single-model serving platform. This mode is useful when you need more control over KServe components, such as modifying resource limits for the KServe controller.