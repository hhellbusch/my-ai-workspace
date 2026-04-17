# Source: ref-21

**URL:** https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html-single/serving_models/index
**Fetched:** 2026-04-17 17:54:36

---

1. [Home](/)
2. [Products](/en/products)
3. [Red Hat OpenShift AI Self-Managed](/en/documentation/red_hat_openshift_ai_self-managed/)
4. [2.16](/en/documentation/red_hat_openshift_ai_self-managed/2.16/)
5. Serving models

# Serving models

---

Red Hat OpenShift AI Self-Managed 2.16

## Serve models in Red Hat OpenShift AI Self-Managed

[Legal Notice](#idm139634623706480)

**Abstract**

Serve models in Red Hat OpenShift AI Self-Managed. Serving trained models enables you to test and implement them into intelligent applications.

---

## [Chapter 1. About model serving](#about-model-serving_about-model-serving) Copy linkLink copied to clipboard!

Serving trained models on Red Hat OpenShift AI means deploying the models on your OpenShift cluster to test and then integrate them into intelligent applications. Deploying a model makes it available as a service that you can access by using an API. This enables you to return predictions based on data inputs that you provide through API calls. This process is known as model *inferencing*. When you serve a model on OpenShift AI, the inference endpoints that you can access for the deployed model are shown in the dashboard.

OpenShift AI provides the following model serving platforms:

Single-model serving platform
:   For deploying large models such as large language models (LLMs), OpenShift AI includes a *single-model serving platform* that is based on the [KServe](https://github.com/kserve/kserve) component. Because each model is deployed from its own model server, the single-model serving platform helps you to deploy, monitor, scale, and maintain large models that require increased resources.

Multi-model serving platform
:   For deploying small and medium-sized models, OpenShift AI includes a *multi-model serving platform* that is based on the [ModelMesh](https://github.com/kserve/modelmesh) component. On the multi-model serving platform, you can deploy multiple models on the same model server. Each of the deployed models shares the server resources. This approach can be advantageous on OpenShift clusters that have finite compute resources or pods.

## [Chapter 2. Serving small and medium-sized models](#serving-small-and-medium-sized-models_model-serving) Copy linkLink copied to clipboard!

For deploying small and medium-sized models, OpenShift AI includes a *multi-model serving platform* that is based on the ModelMesh component. On the multi-model serving platform, multiple models can be deployed from the same model server and share the server resources.

### [2.1. Configuring model servers](#configuring_model_servers) Copy linkLink copied to clipboard!

#### [2.1.1. Enabling the multi-model serving platform](#enabling-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

To use the multi-model serving platform, you must first enable the platform.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* Your cluster administrator has *not* edited the OpenShift AI dashboard configuration to disable the ability to select the multi-model serving platform, which uses the ModelMesh component. For more information, see [Dashboard configuration options](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16//html/managing_openshift_ai/customizing-the-dashboard#ref-dashboard-configuration-options_dashboard).

**Procedure**

1. In the left menu of the OpenShift AI dashboard, click **Settings** → **Cluster settings**.
2. Locate the **Model serving platforms** section.
3. Select the **Multi-model serving platform** checkbox.
4. Click **Save changes**.

#### [2.1.2. Adding a custom model-serving runtime for the multi-model serving platform](#adding-a-custom-model-serving-runtime-for-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

A model-serving runtime adds support for a specified set of model frameworks and the model formats supported by those frameworks. By default, the multi-model serving platform includes the OpenVINO Model Server runtime. You can also add your own custom runtime if the default runtime does not meet your needs, such as supporting a specific model format.

As an administrator, you can use the Red Hat OpenShift AI dashboard to add and enable a custom model-serving runtime. You can then choose the custom runtime when you create a new model server for the multi-model serving platform.

Note

Red Hat does not provide support for custom runtimes. You are responsible for ensuring that you are licensed to use any custom runtimes that you add, and for correctly configuring and maintaining them.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You are familiar with how to [add a model server to your project](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-small-and-medium-sized-models_model-serving#adding-a-model-server-for-the-multi-model-serving-platform_model-serving). When you have added a custom model-serving runtime, you must configure a new model server to use the runtime.
* You have reviewed the example runtimes in the [kserve/modelmesh-serving](https://github.com/kserve/modelmesh-serving/tree/main/config/runtimes) repository. You can use these examples as starting points. However, each runtime requires some further modification before you can deploy it in OpenShift AI. The required modifications are described in the following procedure.

  Note

  OpenShift AI includes the OpenVINO Model Server runtime by default. You do not need to add this runtime to OpenShift AI.

**Procedure**

1. From the OpenShift AI dashboard, click **Settings** > **Serving runtimes**.

   The **Serving runtimes** page opens and shows the model-serving runtimes that are already installed and enabled.
2. To add a custom runtime, choose one of the following options:

   * To start with an existing runtime (for example the OpenVINO Model Server runtime), click the action menu (⋮) next to the existing runtime and then click **Duplicate**.
   * To add a new custom runtime, click **Add serving runtime**.
3. In the **Select the model serving platforms this runtime supports** list, select **Multi-model serving platform**.

   Note

   The multi-model serving platform supports only the REST protocol. Therefore, you cannot change the default value in the **Select the API protocol this runtime supports** list.
4. Optional: If you started a new runtime (rather than duplicating an existing one), add your code by choosing one of the following options:

   * **Upload a YAML file**

     1. Click **Upload files**.
     2. In the file browser, select a YAML file on your computer. This file might be the one of the example runtimes that you downloaded from the [kserve/modelmesh-serving](https://github.com/kserve/modelmesh-serving/tree/main/config/runtimes) repository.

        The embedded YAML editor opens and shows the contents of the file that you uploaded.
   * **Enter YAML code directly in the editor**

     1. Click **Start from scratch**.
     2. Enter or paste YAML code directly in the embedded editor. The YAML that you paste might be copied from one of the example runtimes in the [kserve/modelmesh-serving](https://github.com/kserve/modelmesh-serving/tree/main/config/runtimes) repository.
5. Optional: If you are adding one of the example runtimes in the [kserve/modelmesh-serving](https://github.com/kserve/modelmesh-serving/tree/main/config/runtimes) repository, perform the following modifications:

   1. In the YAML editor, locate the `kind` field for your runtime. Update the value of this field to `ServingRuntime`.
   2. In the [kustomization.yaml](https://github.com/kserve/modelmesh-serving/blob/main/config/runtimes/kustomization.yaml) file in the [kserve/modelmesh-serving](https://github.com/kserve/modelmesh-serving/tree/main/config/runtimes) repository, take note of the `newName` and `newTag` values for the runtime that you want to add. You will specify these values in a later step.
   3. In the YAML editor for your custom runtime, locate the `containers.image` field.
   4. Update the value of the `containers.image` field in the format `newName:newTag`, based on the values that you previously noted in the [kustomization.yaml](https://github.com/kserve/modelmesh-serving/blob/main/config/runtimes/kustomization.yaml) file. Some examples are shown.

      Nvidia Triton Inference Server
      :   `image: nvcr.io/nvidia/tritonserver:23.04-py3`

      Seldon Python MLServer
      :   `image: seldonio/mlserver:1.3.2`

      TorchServe
      :   `image: pytorch/torchserve:0.7.1-cpu`
6. In the `metadata.name` field, ensure that the value of the runtime you are adding is unique (that is, the value doesn’t match a runtime that you have already added).
7. Optional: To configure a custom display name for the runtime that you are adding, add a `metadata.annotations.openshift.io/display-name` field and specify a value, as shown in the following example:

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: ServingRuntime
   metadata:
     name: mlserver-0.x
     annotations:
       openshift.io/display-name: MLServer
   ```

   Note

   If you do not configure a custom display name for your runtime, OpenShift AI shows the value of the `metadata.name` field.
8. Click **Add**.

   The **Serving runtimes** page opens and shows the updated list of runtimes that are installed. Observe that the runtime you added is automatically enabled.
9. Optional: To edit your custom runtime, click the action menu (⋮) and select **Edit**.

**Verification**

* The custom model-serving runtime that you added is shown in an enabled state on the **Serving runtimes** page.

#### [2.1.3. Adding a tested and verified model-serving runtime for the multi-model serving platform](#adding-a-tested-and-verified-model-serving-runtime-for-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

In addition to preinstalled and custom model-serving runtimes, you can also use Red Hat tested and verified model-serving runtimes such as the [NVIDIA Triton Inference Server](https://developer.nvidia.com/triton-inference-server) to support your needs. For more information about Red Hat tested and verified runtimes, see [Tested and verified runtimes for Red Hat OpenShift AI](https://access.redhat.com/articles/7089743).

You can use the Red Hat OpenShift AI dashboard to add and enable the **NVIDIA Triton Inference Server** runtime and then choose the runtime when you create a new model server for the multi-model serving platform.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You are familiar with how to [add a model server to your project](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-small-and-medium-sized-models_model-serving#adding-a-model-server-for-the-multi-model-serving-platform_model-serving). After you have added a tested and verified model-serving runtime, you must configure a new model server to use the runtime.

**Procedure**

1. From the OpenShift AI dashboard, click **Settings** > **Serving runtimes**.

   The **Serving runtimes** page opens and shows the model-serving runtimes that are already installed and enabled.
2. To add a tested and verified runtime, click **Add serving runtime**.
3. In the **Select the model serving platforms this runtime supports** list, select **Multi-model serving platform**.

   Note

   The multi-model serving platform supports only the REST protocol. Therefore, you cannot change the default value in the **Select the API protocol this runtime supports** list.
4. Click **Start from scratch**.
5. Enter or paste the following YAML code directly in the embedded editor.

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: ServingRuntime
   metadata:
     annotations:
       enable-route: "true"
     name: modelmesh-triton
     labels:
       opendatahub.io/dashboard: "true"
   spec:
     annotations:
       opendatahub.io/modelServingSupport: '["multi"x`x`]'
       prometheus.kserve.io/path: /metrics
       prometheus.kserve.io/port: "8002"
     builtInAdapter:
       env:
         - name: CONTAINER_MEM_REQ_BYTES
           value: "268435456"
         - name: USE_EMBEDDED_PULLER
           value: "true"
       memBufferBytes: 134217728
       modelLoadingTimeoutMillis: 90000
       runtimeManagementPort: 8001
       serverType: triton
     containers:
       - args:
           - -c
           - 'mkdir -p /models/_triton_models;  chmod 777
             /models/_triton_models;  exec
             tritonserver "--model-repository=/models/_triton_models" "--model-control-mode=explicit" "--strict-model-config=false" "--strict-readiness=false" "--allow-http=true" "--allow-grpc=true"  '
         command:
           - /bin/sh
         image: nvcr.io/nvidia/tritonserver@sha256:xxxxx
         name: triton
         resources:
           limits:
             cpu: "1"
             memory: 2Gi
           requests:
             cpu: "1"
             memory: 2Gi
     grpcDataEndpoint: port:8001
     grpcEndpoint: port:8085
     multiModel: true
     protocolVersions:
       - grpc-v2
       - v2
     supportedModelFormats:
       - autoSelect: true
         name: onnx
         version: "1"
       - autoSelect: true
         name: pytorch
         version: "1"
       - autoSelect: true
         name: tensorflow
         version: "1"
       - autoSelect: true
         name: tensorflow
         version: "2"
       - autoSelect: true
         name: tensorrt
         version: "7"
       - autoSelect: false
         name: xgboost
         version: "1"
       - autoSelect: true
         name: python
         version: "1"
   ```
6. In the `metadata.name` field, make sure that the value of the runtime you are adding does not match a runtime that you have already added).
7. Optional: To use a custom display name for the runtime that you are adding, add a `metadata.annotations.openshift.io/display-name` field and specify a value, as shown in the following example:

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: ServingRuntime
   metadata:
     name: modelmesh-triton
     annotations:
       openshift.io/display-name: Triton ServingRuntime
   ```

   Note

   If you do not configure a custom display name for your runtime, OpenShift AI shows the value of the `metadata.name` field.
8. Click **Create**.

   The **Serving runtimes** page opens and shows the updated list of runtimes that are installed. Observe that the runtime you added is automatically enabled.
9. Optional: To edit the runtime, click the action menu (⋮) and select **Edit**.

**Verification**

* The model-serving runtime that you added is shown in an enabled state on the **Serving runtimes** page.

#### [2.1.4. Adding a model server for the multi-model serving platform](#adding-a-model-server-for-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

When you have enabled the multi-model serving platform, you must configure a model server to deploy models. If you require extra computing power for use with large datasets, you can assign accelerators to your model server.

Note

In OpenShift AI 2.16, Red Hat supports only NVIDIA and AMD GPU accelerators for model serving.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* If you use OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins` ) in OpenShift.
* You have created a data science project that you can add a model server to.
* You have enabled the multi-model serving platform.
* If you want to use a custom model-serving runtime for your model server, you have added and enabled the runtime. See [Adding a custom model-serving runtime](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-small-and-medium-sized-models_model-serving#adding-a-custom-model-serving-runtime-for-the-multi-model-serving-platform_model-serving).
* If you want to use graphics processing units (GPUs) with your model server, you have enabled GPU support in OpenShift AI. If you use NVIDIA GPUs, see [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai). If you use AMD GPUs, see [AMD GPU integration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#amd-gpu-integration_managing-rhoai).

**Procedure**

1. In the left menu of the OpenShift AI dashboard, click **Data Science Projects**.

   The **Data Science Projects** page opens.
2. Click the name of the project that you want to configure a model server for.

   A project details page opens.
3. Click the **Models** tab.
4. Perform one of the following actions:

   * If you see a **​Multi-model serving platform** tile, click **Add model server** on the tile.
   * If you do not see any tiles, click the **Add model server** button.

   The **Add model server** dialog opens.
5. In the **Model server name** field, enter a unique name for the model server.
6. From the **Serving runtime** list, select a model-serving runtime that is installed and enabled in your OpenShift AI deployment.

   Note

   If you are using a *custom* model-serving runtime with your model server and want to use GPUs, you must ensure that your custom runtime supports GPUs and is appropriately configured to use them.
7. In the **Number of model replicas to deploy** field, specify a value.
8. From the **Model server size** list, select a value.
9. Optional: If you selected **Custom** in the preceding step, configure the following settings in the **Model server size** section to customize your model server:

   1. In the **CPUs requested** field, specify the number of CPUs to use with your model server. Use the list beside this field to specify the value in cores or millicores.
   2. In the **CPU limit** field, specify the maximum number of CPUs to use with your model server. Use the list beside this field to specify the value in cores or millicores.
   3. In the **Memory requested** field, specify the requested memory for the model server in gibibytes (Gi).
   4. In the **Memory limit** field, specify the maximum memory limit for the model server in gibibytes (Gi).
10. Optional: From the **Accelerator** list, select an accelerator.

    1. If you selected an accelerator in the preceding step, specify the number of accelerators to use.
11. Optional: In the **Model route** section, select the **Make deployed models available through an external route** checkbox to make your deployed models available to external clients.
12. Optional: In the **Token authorization** section, select the **Require token authentication** checkbox to require token authentication for your model server. To finish configuring token authentication, perform the following actions:

    1. In the **Service account name** field, enter a service account name for which the token will be generated. The generated token is created and displayed in the **Token secret** field when the model server is configured.
    2. To add an additional service account, click **Add a service account** and enter another service account name.
13. Click **Add**.

    * The model server that you configured appears on the **Models** tab for the project, in the **Models and model servers** list.
14. Optional: To update the model server, click the action menu (**⋮**) beside the model server and select **Edit model server**.

#### [2.1.5. Deleting a model server](#deleting-a-model-server_model-serving) Copy linkLink copied to clipboard!

When you no longer need a model server to host models, you can remove it from your data science project.

Note

When you remove a model server, you also remove the models that are hosted on that model server. As a result, the models are no longer available to applications.

**Prerequisites**

* You have created a data science project and an associated model server.
* You have notified the users of the applications that access the models that the models will no longer be available.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.

**Procedure**

1. From the OpenShift AI dashboard, click **Data Science Projects**.

   The **Data Science Projects** page opens.
2. Click the name of the project from which you want to delete the model server.

   A project details page opens.
3. Click the **Models** tab.
4. Click the action menu (**⋮**) beside the project whose model server you want to delete and then click **Delete model server**.

   The **Delete model server** dialog opens.
5. Enter the name of the model server in the text field to confirm that you intend to delete it.
6. Click **Delete model server**.

**Verification**

* The model server that you deleted is no longer displayed on the **Models** tab for the project.

### [2.2. Working with deployed models](#working_with_deployed_models) Copy linkLink copied to clipboard!

#### [2.2.1. Deploying a model by using the multi-model serving platform](#deploying-a-model-using-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

You can deploy trained models on OpenShift AI to enable you to test and implement them into intelligent applications. Deploying a model makes it available as a service that you can access by using an API. This enables you to return predictions based on data inputs.

When you have enabled the multi-model serving platform, you can deploy models on the platform.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users`) in OpenShift.
* You have enabled the multi-model serving platform.
* You have created a data science project and added a model server.
* You have access to S3-compatible object storage.
* For the model that you want to deploy, you know the associated folder path in your S3-compatible object storage bucket.

**Procedure**

1. In the left menu of the OpenShift AI dashboard, click **Data Science Projects**.

   The **Data Science Projects** page opens.
2. Click the name of the project that you want to deploy a model in.

   A project details page opens.
3. Click the **Models** tab.
4. Click **Deploy model**.
5. Configure properties for deploying your model as follows:

   1. In the **Model name** field, enter a unique name for the model that you are deploying.
   2. From the **Model framework** list, select a framework for your model.

      Note

      The **Model framework** list shows only the frameworks that are supported by the model-serving runtime that you specified when you configured your model server.
   3. To specify the location of the model you want to deploy from S3-compatible object storage, perform one of the following sets of actions:

      * **To use an existing connection**

        1. Select **Existing connection**.
        2. From the **Name** list, select a connection that you previously defined.
        3. In the **Path** field, enter the folder path that contains the model in your specified data source.
      * **To use a new connection**

        1. To define a new connection that your model can access, select **New connection**.
        2. In the **Add connection** modal, select a **Connection type**. The **S3 compatible object storage** and **URI** options are pre-installed connection types. Additional options might be available if your OpenShift AI administrator added them.

           The **Add connection** form opens with fields specific to the connection type that you selected.
        3. Enter the connection detail fields.
   4. (Optional) Customize the runtime parameters in the **Configuration parameters** section:

      1. Modify the values in **Additional serving runtime arguments** to define how the deployed model behaves.
      2. Modify the values in **Additional environment variables** to define variables in the model’s environment.
   5. Click **Deploy**.

**Verification**

* Confirm that the deployed model is shown on the **Models** tab for the project, and on the **Model Serving** page of the dashboard with a checkmark in the **Status** column.

#### [2.2.2. Viewing a deployed model](#viewing-a-deployed-model_model-serving) Copy linkLink copied to clipboard!

To analyze the results of your work, you can view a list of deployed models on Red Hat OpenShift AI. You can also view the current statuses of deployed models and their endpoints.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.

**Procedure**

1. From the OpenShift AI dashboard, click **Model Serving**.

   The **Deployed models** page opens.

   For each model, the page shows details such as the model name, the project in which the model is deployed, the model-serving runtime that the model uses, and the deployment status.
2. Optional: For a given model, click the link in the **Inference endpoint** column to see the inference endpoints for the deployed model.

**Verification**

* A list of previously deployed data science models is displayed on the **Deployed models** page.

#### [2.2.3. Updating the deployment properties of a deployed model](#updating-the-deployment-properties-of-a-deployed-model_model-serving) Copy linkLink copied to clipboard!

You can update the deployment properties of a model that has been deployed previously. For example, you can change the model’s connection and name.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.
* You have deployed a model on OpenShift AI.

**Procedure**

1. From the OpenShift AI dashboard, click **Model Serving**.

   The **Deployed models** page opens.
2. Click the action menu (**⋮**) beside the model whose deployment properties you want to update and click **Edit**.

   The **Edit model** dialog opens.
3. Update the deployment properties of the model as follows:

   1. In the **Model name** field, enter a new, unique name for your model.
   2. From the **Model servers** list, select a model server for your model.
   3. From the **Model framework** list, select a framework for your model.

      Note

      The **Model framework** list shows only the frameworks that are supported by the model-serving runtime that you specified when you configured your model server.
   4. Optionally, update the connection by specifying an existing connection or by creating a new connection.
   5. Click **Redeploy**.

**Verification**

* The model whose deployment properties you updated is displayed on the **Model Serving** page of the dashboard.

#### [2.2.4. Deleting a deployed model](#deleting-a-deployed-model_model-serving) Copy linkLink copied to clipboard!

You can delete models you have previously deployed. This enables you to remove deployed models that are no longer required.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.
* You have deployed a model.

**Procedure**

1. From the OpenShift AI dashboard, click **Model serving**.

   The **Deployed models** page opens.
2. Click the action menu (**⋮**) beside the deployed model that you want to delete and click **Delete**.

   The **Delete deployed model** dialog opens.
3. Enter the name of the deployed model in the text field to confirm that you intend to delete it.
4. Click **Delete deployed model**.

**Verification**

* The model that you deleted is no longer displayed on the **Deployed models** page.

### [2.3. Configuring monitoring for the multi-model serving platform](#configuring-monitoring-for-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

The multi-model serving platform includes model and model server metrics for the ModelMesh component. ModelMesh generates its own set of metrics and does not rely on the underlying model-serving runtimes to provide them. The set of metrics that ModelMesh generates includes metrics for model request rates and timings, model loading and unloading rates, times and sizes, internal queuing delays, capacity and usage, cache state, and least recently-used models. For more information, see [ModelMesh metrics](https://github.com/kserve/modelmesh-serving/blob/main/docs/monitoring.md).

After you have configured monitoring, you can view metrics for the ModelMesh component.

**Prerequisites**

* You have cluster administrator privileges for your OpenShift cluster.
* You have downloaded and installed the OpenShift command-line interface (CLI). See [Installing the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/cli_tools/openshift-cli-oc#installing-openshift-cli).
* You are familiar with [creating a config map](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/monitoring/configuring-the-monitoring-stack#creating-user-defined-workload-monitoring-configmap_configuring-the-monitoring-stack) for monitoring a user-defined workflow. You will perform similar steps in this procedure.
* You are familiar with [enabling monitoring](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/monitoring/enabling-monitoring-for-user-defined-projects) for user-defined projects in OpenShift. You will perform similar steps in this procedure.
* You have [assigned](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/monitoring/enabling-monitoring-for-user-defined-projects#granting-users-permission-to-monitor-user-defined-projects_enabling-monitoring-for-user-defined-projects) the `monitoring-rules-view` role to users that will monitor metrics.

**Procedure**

1. In a terminal window, if you are not already logged in to your OpenShift cluster as a cluster administrator, log in to the OpenShift CLI as shown in the following example:

   ```
   $ oc login <openshift_cluster_url> -u <admin_username> -p <password>
   ```
2. Define a `ConfigMap` object in a YAML file called `uwm-cm-conf.yaml` with the following contents:

   ```
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: user-workload-monitoring-config
     namespace: openshift-user-workload-monitoring
   data:
     config.yaml: |
       prometheus:
         logLevel: debug
         retention: 15d
   ```

   The `user-workload-monitoring-config` object configures the components that monitor user-defined projects. Observe that the retention time is set to the recommended value of 15 days.
3. Apply the configuration to create the `user-workload-monitoring-config` object.

   ```
   $ oc apply -f uwm-cm-conf.yaml
   ```
4. Define another `ConfigMap` object in a YAML file called `uwm-cm-enable.yaml` with the following contents:

   ```
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: cluster-monitoring-config
     namespace: openshift-monitoring
   data:
     config.yaml: |
       enableUserWorkload: true
   ```

   The `cluster-monitoring-config` object enables monitoring for user-defined projects.
5. Apply the configuration to create the `cluster-monitoring-config` object.

   ```
   $ oc apply -f uwm-cm-enable.yaml
   ```

### [2.4. Viewing model-serving runtime metrics for the multi-model serving platform](#viewing-metrics-for-the-multi-model-serving-platform_model-serving) Copy linkLink copied to clipboard!

After a cluster administrator has configured monitoring for the multi-model serving platform, non-admin users can use the OpenShift web console to view model-serving runtime metrics for the ModelMesh component.

**Prerequisites**

* A cluster administrator has configured monitoring for the multi-model serving platform.
* You have been assigned the `monitoring-rules-view` role. For more information, see [Granting users permission to configure monitoring for user-defined projects](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/monitoring/enabling-monitoring-for-user-defined-projects#granting-users-permission-to-configure-monitoring-for-user-defined-projects_enabling-monitoring-for-user-defined-projects).
* You are familiar with how to monitor project metrics in the OpenShift web console. For more information, see [Monitoring your project metrics](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/building_applications/odc-monitoring-project-and-application-metrics-using-developer-perspective#odc-monitoring-your-project-metrics_monitoring-project-and-application-metrics-using-developer-perspective).

**Procedure**

1. Log in to the OpenShift web console.
2. Switch to the **Developer** perspective.
3. In the left menu, click **Observe**.
4. As described in [Monitoring your project metrics](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/building_applications/odc-monitoring-project-and-application-metrics-using-developer-perspective#odc-monitoring-your-project-metrics_monitoring-project-and-application-metrics-using-developer-perspective), use the web console to run queries for `modelmesh_*` metrics.

### [2.5. Monitoring model performance](#monitoring_model_performance) Copy linkLink copied to clipboard!

In the multi-model serving platform, you can view performance metrics for all models deployed on a model server and for a specific model that is deployed on the model server.

#### [2.5.1. Viewing performance metrics for all models on a model server](#viewing-performance-metrics-for-model-server_model-serving) Copy linkLink copied to clipboard!

You can monitor the following metrics for all the models that are deployed on a model server:

* **HTTP requests per 5 minutes** - The number of HTTP requests that have failed or succeeded for all models on the server.
* **Average response time (ms)** - For all models on the server, the average time it takes the model server to respond to requests.
* **CPU utilization (%)** - The percentage of the CPU’s capacity that is currently being used by all models on the server.
* **Memory utilization (%)** - The percentage of the system’s memory that is currently being used by all models on the server.

You can specify a time range and a refresh interval for these metrics to help you determine, for example, when the peak usage hours are and how the models are performing at a specified time.

**Prerequisites**

* You have installed Red Hat OpenShift AI.
* On the OpenShift cluster where OpenShift AI is installed, user workload monitoring is enabled.
* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.
* You have deployed models on the multi-model serving platform.

**Procedure**

1. From the OpenShift AI dashboard navigation menu, click **Data Science Projects**.

   The **Data Science Projects** page opens.
2. Click the name of the project that contains the data science models that you want to monitor.
3. In the project details page, click the **Models** tab.
4. In the row for the model server that you are interested in, click the action menu (⋮) and then select **View model server metrics**.
5. Optional: On the metrics page for the model server, set the following options:

   * **Time range** - Specifies how long to track the metrics. You can select one of these values: 1 hour, 24 hours, 7 days, and 30 days.
   * **Refresh interval** - Specifies how frequently the graphs on the metrics page are refreshed (to show the latest data). You can select one of these values: 15 seconds, 30 seconds, 1 minute, 5 minutes, 15 minutes, 30 minutes, 1 hour, 2 hours, and 1 day.
6. Scroll down to view data graphs for HTTP requests per 5 minutes, average response time, CPU utilization, and memory utilization.

**Verification**

On the metrics page for the model server, the graphs provide data on performance metrics.

#### [2.5.2. Viewing HTTP request metrics for a deployed model](#viewing-http-request-metrics-for-a-deployed-model_model-serving) Copy linkLink copied to clipboard!

You can view a graph that illustrates the HTTP requests that have failed or succeeded for a specific model that is deployed on the multi-model serving platform.

**Prerequisites**

* You have installed Red Hat OpenShift AI.
* On the OpenShift cluster where OpenShift AI is installed, user workload monitoring is enabled.
* The following dashboard configuration options are set to the default values as shown:

  ```
  disablePerformanceMetrics:false
  disableKServeMetrics:false
  ```

  For more information, see [Dashboard configuration options](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/customizing-the-dashboard#ref-dashboard-configuration-options_dashboard).
* You have logged in to Red Hat OpenShift AI.
* If you are using OpenShift AI groups, you are part of the user group or admin group (for example, `rhoai-users` or `rhoai-admins`) in OpenShift.
* You have deployed models on the multi-model serving platform.

**Procedure**

1. From the OpenShift AI dashboard navigation menu, select **Model Serving**.
2. On the **Deployed models** page, select the model that you are interested in.
3. Optional: On the **Endpoint performance** tab, set the following options:

   * **Time range** - Specifies how long to track the metrics. You can select one of these values: 1 hour, 24 hours, 7 days, and 30 days.
   * **Refresh interval** - Specifies how frequently the graphs on the metrics page are refreshed (to show the latest data). You can select one of these values: 15 seconds, 30 seconds, 1 minute, 5 minutes, 15 minutes, 30 minutes, 1 hour, 2 hours, and 1 day.

**Verification**

The **Endpoint performance** tab shows a graph of the HTTP metrics for the model.

## [Chapter 3. Serving large models](#serving-large-models_serving-large-models) Copy linkLink copied to clipboard!

For deploying large models such as large language models (LLMs), Red Hat OpenShift AI includes a *single model serving platform* that is based on the KServe component. Because each model is deployed from its own model server, the single model serving platform helps you to deploy, monitor, scale, and maintain large models that require increased resources.

### [3.1. About the single-model serving platform](#about-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

For deploying large models such as large language models (LLMs), OpenShift AI includes a single-model serving platform that is based on the [KServe](https://github.com/kserve/kserve) component. Because each model is deployed on its own model server, the single-model serving platform helps you to deploy, monitor, scale, and maintain large models that require increased resources.

### [3.2. Components](#components) Copy linkLink copied to clipboard!

* [KServe](https://github.com/opendatahub-io/kserve): A Kubernetes custom resource definition (CRD) that orchestrates model serving for all types of models. KServe includes model-serving runtimes that implement the loading of given types of model servers. KServe also handles the lifecycle of the deployment object, storage access, and networking setup.
* [Red Hat OpenShift Serverless](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/serverless/about-serverless): A cloud-native development model that allows for serverless deployments of models. OpenShift Serverless is based on the open source [Knative](https://knative.dev/docs/) project.
* [Red Hat OpenShift Service Mesh](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/service_mesh/service-mesh-2-x#ossm-understanding-service-mesh_ossm-architecture): A service mesh networking layer that manages traffic flows and enforces access policies. OpenShift Service Mesh is based on the open source [Istio](https://istio.io/) project.

### [3.3. Installation options](#installation-options) Copy linkLink copied to clipboard!

To install the single-model serving platform, you have the following options:

Automated installation
:   If you have not already created a `ServiceMeshControlPlane` or `KNativeServing` resource on your OpenShift cluster, you can configure the Red Hat OpenShift AI Operator to install KServe and configure its dependencies.

    For more information about automated installation, see [Configuring automated installation of KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#configuring-automated-installation-of-kserve_component-install).

Manual installation
:   If you have already created a `ServiceMeshControlPlane` or `KNativeServing` resource on your OpenShift cluster, you *cannot* configure the Red Hat OpenShift AI Operator to install KServe and configure its dependencies. In this situation, you must install KServe manually.

    For more information about manual installation, see [Manually installing KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#manually-installing-kserve_component-install).

### [3.4. Authorization](#authorization) Copy linkLink copied to clipboard!

You can add [Authorino](https://github.com/kuadrant/authorino) as an authorization provider for the single-model serving platform. Adding an authorization provider allows you to enable token authorization for models that you deploy on the platform, which ensures that only authorized parties can make inference requests to the models.

To add Authorino as an authorization provider on the single-model serving platform, you have the following options:

* If automated installation of the single-model serving platform is possible on your cluster, you can include Authorino as part of the automated installation process.
* If you need to manually install the single-model serving platform, you must also manually configure Authorino.

For guidance on choosing an installation option for the single-model serving platform, see [Installation options](#installation-options "3.3. Installation options").

### [3.5. Monitoring](#monitoring) Copy linkLink copied to clipboard!

You can configure monitoring for the single-model serving platform and use Prometheus to scrape metrics for each of the pre-installed model-serving runtimes.

### [3.6. Model-serving runtimes](#model-serving-runtimes_serving-large-models) Copy linkLink copied to clipboard!

You can serve models on the single-model serving platform by using model-serving runtimes. The configuration of a model-serving runtime is defined by the **ServingRuntime** and **InferenceService** custom resource definitions (CRDs).

#### [3.6.1. ServingRuntime](#servingruntime) Copy linkLink copied to clipboard!

The **ServingRuntime** CRD creates a serving runtime, an environment for deploying and managing a model. It creates the templates for pods that dynamically load and unload models of various formats and also exposes a service endpoint for inferencing requests.

The following YAML configuration is an example of the **vLLM ServingRuntime for KServe** model-serving runtime. The configuration includes various flags, environment variables and command-line arguments.

```
apiVersion: serving.kserve.io/v1alpha1
kind: ServingRuntime
metadata:
  annotations:
    opendatahub.io/recommended-accelerators: '["nvidia.com/gpu"]'
```

1

```
    openshift.io/display-name: vLLM ServingRuntime for KServe
```

2

```
  labels:
    opendatahub.io/dashboard: "true"
  name: vllm-runtime
spec:
     annotations:
          prometheus.io/path: /metrics
```

3

```
          prometheus.io/port: "8080"
```

4

```
     containers :
          - args:
               - --port=8080
               - --model=/mnt/models
```

5

```
               - --served-model-name={{.Name}}
```

6

```
             command:
```

7

```
                  - python
                  - '-m'
                  - vllm.entrypoints.openai.api_server
             env:
                  - name: HF_HOME
                     value: /tmp/hf_home
             image:
```

8

```
quay.io/modh/vllm@sha256:8a3dd8ad6e15fe7b8e5e471037519719d4d8ad3db9d69389f2beded36a6f5b21
          name: kserve-container
          ports:
               - containerPort: 8080
                   protocol: TCP
    multiModel: false
```

9

```
    supportedModelFormats:
```

10

```
        - autoSelect: true
           name: vLLM
```

[1](#CO1-1)
:   The recommended accelerator to use with the runtime.

[2](#CO1-2)
:   The name with which the serving runtime is displayed.

[3](#CO1-3)
:   The endpoint used by Prometheus to scrape metrics for monitoring.

[4](#CO1-4)
:   The port used by Prometheus to scrape metrics for monitoring.

[5](#CO1-5)
:   The path to where the model files are stored in the runtime container.

[6](#CO1-6)
:   Passes the model name that is specified by the `{{.Name}}` template variable inside the runtime container specification to the runtime environment. The `{{.Name}}` variable maps to the `spec.predictor.name` field in the `InferenceService` metadata object.

[7](#CO1-7)
:   The entrypoint command that starts the runtime container.

[8](#CO1-8)
:   The runtime container image used by the serving runtime. This image differs depending on the type of accelerator used.

[9](#CO1-9)
:   Specifies that the runtime is used for single-model serving.

[10](#CO1-10)
:   Specifies the model formats supported by the runtime.

#### [3.6.2. InferenceService](#inferenceservice) Copy linkLink copied to clipboard!

The **InferenceService** CRD creates a server or inference service that processes inference queries, passes it to the model, and then returns the inference output.

The inference service also performs the following actions:

* Specifies the location and format of the model.
* Specifies the serving runtime used to serve the model.
* Enables the passthrough route for gRPC or REST inference.
* Defines HTTP or gRPC endpoints for the deployed model.

The following example shows the InferenceService YAML configuration file that is generated when deploying a granite model with the vLLM runtime:

```
apiVersion: serving.kserve.io/v1beta1
kind: InferenceService
metadata:
  annotations:
    openshift.io/display-name: granite
    serving.knative.openshift.io/enablePassthrough: 'true'
    sidecar.istio.io/inject: 'true'
    sidecar.istio.io/rewriteAppHTTPProbers: 'true'
  name: granite
  labels:
    opendatahub.io/dashboard: 'true'
spec:
  predictor:
    maxReplicas: 1
    minReplicas: 1
    model:
      modelFormat:
        name: vLLM
      name: ''
      resources:
        limits:
          cpu: '6'
          memory: 24Gi
          nvidia.com/gpu: '1'
        requests:
          cpu: '1'
          memory: 8Gi
          nvidia.com/gpu: '1'
      runtime: vLLM ServingRuntime for KServe
      storage:
        key: aws-connection-my-storage
        path: models/granite-7b-instruct/
    tolerations:
      - effect: NoSchedule
        key: nvidia.com/gpu
        operator: Exists
```

### [3.7. Supported model-serving runtimes](#supported-model-serving-runtimes_serving-large-models) Copy linkLink copied to clipboard!

OpenShift AI includes several preinstalled model-serving runtimes. You can use preinstalled model-serving runtimes to start serving models without modifying or defining the runtime yourself. You can also add a custom runtime to support a model.

For help adding a custom runtime, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

Expand

Table 3.1. Model-serving runtimes

| Name | Description | Exported model format |
| --- | --- | --- |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe (1) | A composite runtime for serving models in the Caikit format | Caikit Text Generation |
| Caikit Standalone ServingRuntime for KServe (2) | A runtime for serving models in the Caikit embeddings format for embeddings tasks | Caikit Embeddings |
| OpenVINO Model Server | A scalable, high-performance runtime for serving models that are optimized for Intel architectures | PyTorch, TensorFlow, OpenVINO IR, PaddlePaddle, MXNet, Caffe, Kaldi |
| Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe (3) | A runtime for serving TGI-enabled models | PyTorch Model Formats |
| vLLM ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime for large language models | [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) |
| vLLM ServingRuntime with Gaudi accelerators support for KServe | A high-throughput and memory-efficient inference and serving runtime that supports Intel Gaudi accelerators | [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) |
| vLLM ROCm ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime that supports AMD GPU accelerators | [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html) |

Show more

1. The composite Caikit-TGIS runtime is based on [Caikit](https://github.com/opendatahub-io/caikit) and [Text Generation Inference Server (TGIS)](https://github.com/IBM/text-generation-inference). To use this runtime, you must convert your models to Caikit format. For an example, see [Converting Hugging Face Hub models to Caikit format](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/built-tip.md#bootstrap-process) in the [caikit-tgis-serving](https://github.com/opendatahub-io/caikit-tgis-serving/tree/main) repository.
2. The Caikit Standalone runtime is based on [Caikit NLP](https://github.com/caikit/caikit-nlp/tree/main). To use this runtime, you must convert your models to the Caikit embeddings format. For an example, see [Tests for text embedding module](https://github.com/caikit/caikit-nlp/blob/main/tests/modules/text_embedding/test_embedding.py).
3. [Text Generation Inference Server (TGIS)](https://github.com/IBM/text-generation-inference) is based on an early fork of [Hugging Face TGI](https://github.com/huggingface/text-generation-inference). Red Hat will continue to develop the standalone TGIS runtime to support TGI models. If a model is incompatible in the current version of OpenShift AI, support might be added in a future version. In the meantime, you can also add your own custom runtime to support a TGI model. For more information, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

Expand

Table 3.2. Deployment requirements

| Name | Default protocol | Additonal protocol | Model mesh support | Single node OpenShift support | Deployment mode |
| --- | --- | --- | --- | --- | --- |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe | REST | gRPC | No | Yes | Raw and serverless |
| Caikit Standalone ServingRuntime for KServe | REST | gRPC | No | Yes | Raw and serverless |
| OpenVINO Model Server | REST | None | Yes | Yes | Raw and serverless |
| Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe | gRPC | None | No | Yes | Raw and serverless |
| vLLM ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM ServingRuntime with Gaudi accelerators support for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM ROCm ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |

Show more

### [3.8. Tested and verified model-serving runtimes](#tested-verified-runtimes_serving-large-models) Copy linkLink copied to clipboard!

Tested and verified runtimes are community versions of model-serving runtimes that have been tested and verified against specific versions of OpenShift AI.

Red Hat tests the current version of a tested and verified runtime each time there is a new version of OpenShift AI. If a new version of a tested and verified runtime is released in the middle of an OpenShift AI release cycle, it will be tested and verified in an upcoming release.

A list of the tested and verified runtimes and compatible versions is available in the [OpenShift AI release notes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html-single/release_notes).

Note

Tested and verified runtimes are not directly supported by Red Hat. You are responsible for ensuring that you are licensed to use any tested and verified runtimes that you add, and for correctly configuring and maintaining them.

For more information, see [Tested and verified runtimes in OpenShift AI](https://access.redhat.com/articles/7089743).

Expand

Table 3.3. Model-serving runtimes

| Name | Description | Exported model format |
| --- | --- | --- |
| NVIDIA Triton Inference Server | An open-source inference-serving software for fast and scalable AI in applications. | TensorRT, TensorFlow, PyTorch, ONNX, OpenVINO, Python, RAPIDS FIL, and more |

Show more

Expand

Table 3.4. Deployment requirements

| Name | Default protocol | Additonal protocol | Model mesh support | Single node OpenShift support | Deployment mode |
| --- | --- | --- | --- | --- | --- |
| NVIDIA Triton Inference Server | gRPC | REST | Yes | Yes | Raw and serverless |

Show more

### [3.9. Inference endpoints](#inference-endpoints_serving-large-models) Copy linkLink copied to clipboard!

These examples show how to use inference endpoints to query the model.

Note

If you enabled token authorization when deploying the model, add the `Authorization` header and specify a token value.

#### [3.9.1. Caikit TGIS ServingRuntime for KServe](#caikit_tgis_servingruntime_for_kserve) Copy linkLink copied to clipboard!

* `:443/api/v1/task/text-generation`
* `:443/api/v1/task/server-streaming-text-generation`

**Example command**

```
curl --json '{"model_id": "<model_name__>", "inputs": "<text>"}' https://<inference_endpoint_url>:443/api/v1/task/server-streaming-text-generation -H 'Authorization: Bearer <token>'
```

#### [3.9.2. Caikit Standalone ServingRuntime for KServe](#caikit_standalone_servingruntime_for_kserve) Copy linkLink copied to clipboard!

If you are serving multiple models, you can query `/info/models` or `:443 caikit.runtime.info.InfoService/GetModelsInfo` to view a list of served models.

**REST endpoints**

* `/api/v1/task/embedding`
* `/api/v1/task/embedding-tasks`
* `/api/v1/task/sentence-similarity`
* `/api/v1/task/sentence-similarity-tasks`
* `/api/v1/task/rerank`
* `/api/v1/task/rerank-tasks`
* `/info/models`
* `/info/version`
* `/info/runtime`

**gRPC endpoints**

* `:443 caikit.runtime.Nlp.NlpService/EmbeddingTaskPredict`
* `:443 caikit.runtime.Nlp.NlpService/EmbeddingTasksPredict`
* `:443 caikit.runtime.Nlp.NlpService/SentenceSimilarityTaskPredict`
* `:443 caikit.runtime.Nlp.NlpService/SentenceSimilarityTasksPredict`
* `:443 caikit.runtime.Nlp.NlpService/RerankTaskPredict`
* `:443 caikit.runtime.Nlp.NlpService/RerankTasksPredict`
* `:443 caikit.runtime.info.InfoService/GetModelsInfo`
* `:443 caikit.runtime.info.InfoService/GetRuntimeInfo`

Note

By default, the Caikit Standalone Runtime exposes REST endpoints. To use gRPC protocol, manually deploy a custom Caikit Standalone ServingRuntime. For more information, see [Adding a custom model-serving runtime for the single-model serving platform](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models).

An example manifest is available in the [caikit-tgis-serving GitHub repository](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/custom-manifests/caikit/caikit-standalone/caikit-standalone-servingruntime-grpc.yaml).

**REST**

```
curl -H 'Content-Type: application/json' -d '{"inputs": "<text>", "model_id": "<model_id>"}' <inference_endpoint_url>/api/v1/task/embedding -H 'Authorization: Bearer <token>'
```

**gRPC**

```
grpcurl -d '{"text": "<text>"}' -H \"mm-model-id: <model_id>\" <inference_endpoint_url>:443 caikit.runtime.Nlp.NlpService/EmbeddingTaskPredict -H 'Authorization: Bearer <token>'
```

#### [3.9.3. TGIS Standalone ServingRuntime for KServe](#tgis_standalone_servingruntime_for_kserve) Copy linkLink copied to clipboard!

* `:443 fmaas.GenerationService/Generate`
* `:443 fmaas.GenerationService/GenerateStream`

  Note

  To query the endpoint for the TGIS standalone runtime, you must also download the files in the [proto](https://github.com/opendatahub-io/text-generation-inference/blob/main/proto) directory of the OpenShift AI `text-generation-inference` repository.

**Example command**

```
grpcurl -proto text-generation-inference/proto/generation.proto -d '{"requests": [{"text":"<text>"}]}' -H 'Authorization: Bearer <token>' -insecure <inference_endpoint_url>:443 fmaas.GenerationService/Generate
```

#### [3.9.4. OpenVINO Model Server](#openvino_model_server) Copy linkLink copied to clipboard!

* `/v2/models/<model-name>/infer`

**Example command**

```
curl -ks <inference_endpoint_url>/v2/models/<model_name>/infer -d '{ "model_name": "<model_name>", "inputs": [{ "name": "<name_of_model_input>", "shape": [<shape>], "datatype": "<data_type>", "data": [<data>] }]}' -H 'Authorization: Bearer <token>'
```

#### [3.9.5. vLLM ServingRuntime for KServe](#vllm_servingruntime_for_kserve) Copy linkLink copied to clipboard!

* `:443/version`
* `:443/docs`
* `:443/v1/models`
* `:443/v1/chat/completions`
* `:443/v1/completions`
* `:443/v1/embeddings`
* `:443/tokenize`
* `:443/detokenize`

  Note

  + The vLLM runtime is compatible with the OpenAI REST API. For a list of models that the vLLM runtime supports, see [Supported models](https://docs.vllm.ai/en/latest/models/supported_models.html).
  + To use the embeddings inference endpoint in vLLM, you must use an embeddings model that the vLLM supports. You cannot use the embeddings endpoint with generative models. For more information, see [Supported embeddings models in vLLM](https://github.com/vllm-project/vllm/pull/3734).
  + As of vLLM v0.5.5, you must provide a chat template while querying a model using the `/v1/chat/completions` endpoint. If your model does not include a predefined chat template, you can use the `chat-template` command-line parameter to specify a chat template in your custom vLLM runtime, as shown in the example. Replace `<CHAT_TEMPLATE>` with the path to your template.

    ```
    containers:
      - args:
          - --chat-template=<CHAT_TEMPLATE>
    ```

    You can use the chat templates that are available as `.jinja` files [here](https://github.com/opendatahub-io/vllm/tree/main/examples) or with the vLLM image under `/apps/data/template`. For more information, see [Chat templates](https://huggingface.co/docs/transformers/main/chat_templating).

  As indicated by the paths shown, the single-model serving platform uses the HTTPS port of your OpenShift router (usually port 443) to serve external API requests.

**Example command**

```
curl -v https://<inference_endpoint_url>:443/v1/chat/completions -H "Content-Type: application/json" -d '{ "messages": [{ "role": "<role>", "content": "<content>" }] -H 'Authorization: Bearer <token>'
```

#### [3.9.6. vLLM ServingRuntime with Gaudi accelerators support for KServe](#vllm_servingruntime_with_gaudi_accelerators_support_for_kserve) Copy linkLink copied to clipboard!

See [vLLM ServingRuntime for KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#vllm_servingruntime_for_kserve).

#### [3.9.7. vLLM ROCm ServingRuntime for KServe](#vllm_rocm_servingruntime_for_kserve) Copy linkLink copied to clipboard!

See [vLLM ServingRuntime for KServe](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#vllm_servingruntime_for_kserve).

#### [3.9.8. NVIDIA Triton Inference Server](#nvidia_triton_inference_server) Copy linkLink copied to clipboard!

**REST endpoints**

* `v2/models/[/versions/<model_version>]/infer`
* `v2/models/<model_name>[/versions/<model_version>]`
* `v2/health/ready`
* `v2/health/live`
* `v2/models/<model_name>[/versions/]/ready`
* `v2`

Note

ModelMesh does not support the following REST endpoints:

* `v2/health/live`
* `v2/health/ready`
* `v2/models/<model_name>[/versions/]/ready`

**Example command**

```
curl -ks <inference_endpoint_url>/v2/models/<model_name>/infer -d '{ "model_name": "<model_name>", "inputs": [{ "name": "<name_of_model_input>", "shape": [<shape>], "datatype": "<data_type>", "data": [<data>] }]}' -H 'Authorization: Bearer <token>'
```

**gRPC endpoints**

* `:443 inference.GRPCInferenceService/ModelInfer`
* `:443 inference.GRPCInferenceService/ModelReady`
* `:443 inference.GRPCInferenceService/ModelMetadata`
* `:443 inference.GRPCInferenceService/ServerReady`
* `:443 inference.GRPCInferenceService/ServerLive`
* `:443 inference.GRPCInferenceService/ServerMetadata`

**Example command**

```
grpcurl -cacert ./openshift_ca_istio_knative.crt -proto ./grpc_predict_v2.proto -d @ -H "Authorization: Bearer <token>" <inference_endpoint_url>:443 inference.GRPCInferenceService/ModelMetadata
```

### [3.10. About KServe deployment modes](#about-kserve-deployment-modes_serving-large-models) Copy linkLink copied to clipboard!

By default, you can deploy models on the single-model serving platform with KServe by using [Red Hat OpenShift Serverless](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/1.33/html/about_openshift_serverless/index), which is a cloud-native development model that allows for serverless deployments of models. OpenShift Serverless is based on the open source [Knative](https://knative.dev/docs/) project. In addition, serverless mode is dependent on the Red Hat OpenShift Serverless Operator.

Alternatively, you can use raw deployment mode, which is not dependent on the Red Hat OpenShift Serverless Operator. With raw deployment mode, you can deploy models with Kubernetes resources, such as `Deployment`, `Service`, `Ingress`, and `Horizontal Pod Autoscaler`.

Important

Deploying a machine learning model using KServe raw deployment mode is a Limited Availability feature. Limited Availability means that you can install and receive support for the feature only with specific approval from the Red Hat AI Business Unit. Without such approval, the feature is unsupported. In addition, this feature is only supported on Self-Managed deployments of single node OpenShift.

There are both advantages and disadvantages to using each of these deployment modes:

#### [3.10.1. Serverless mode](#serverless_mode) Copy linkLink copied to clipboard!

Advantages:

* Enables autoscaling based on request volume:

  + Resources scale up automatically when receiving incoming requests.
  + Optimizes resource usage and maintains performance during peak times.
* Supports scale down to and from zero using Knative:

  + Allows resources to scale down completely when there are no incoming requests.
  + Saves costs by not running idle resources.

Disadvantages:

* Has customization limitations:

  + Serverless is limited to Knative, such as when mounting multiple volumes.
* Dependency on Knative for scaling:

  + Introduces additional complexity in setup and management compared to traditional scaling methods.

#### [3.10.2. Raw deployment mode](#raw_deployment_mode) Copy linkLink copied to clipboard!

Advantages:

* Enables deployment with Kubernetes resources, such as `Deployment`, `Service`, `Ingress`, and `Horizontal Pod Autoscaler`:

  + Provides full control over Kubernetes resources, allowing for detailed customization and configuration of deployment settings.
* Unlocks Knative limitations, such as being unable to mount multiple volumes:

  + Beneficial for applications requiring complex configurations or multiple storage mounts.

Disadvantages:

* Does not support automatic scaling:

  + Does not support automatic scaling down to zero resources when idle.
  + Might result in higher costs during periods of low traffic.
* Requires manual management of scaling.

### [3.11. Deploying models on single node OpenShift using KServe raw deployment mode](#deploying-models-on-single-node-openshift-using-kserve-raw-deployment-mode_serving-large-models) Copy linkLink copied to clipboard!

You can deploy a machine learning model by using KServe raw deployment mode on single node OpenShift. Raw deployment mode offers several advantages over Knative, such as the ability to mount multiple volumes.

Important

Deploying a machine learning model using KServe raw deployment mode on single node OpenShift is a Limited Availability feature. Limited Availability means that you can install and receive support for the feature only with specific approval from the Red Hat AI Business Unit. Without such approval, the feature is unsupported.

**Prerequisites**

* You have logged in to Red Hat OpenShift AI.
* You have cluster administrator privileges for your OpenShift cluster.
* You have created an OpenShift cluster that has a node with at least 4 CPUs and 16 GB memory.
* You have installed the Red Hat OpenShift AI (RHOAI) Operator.
* You have installed the OpenShift command-line interface (CLI). For more information about installing the OpenShift command-line interface (CLI), see [Getting started with the OpenShift CLI](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/cli_tools/openshift-cli-oc#cli-getting-started).
* You have installed KServe.
* You have access to S3-compatible object storage.
* For the model that you want to deploy, you know the associated folder path in your S3-compatible object storage bucket.
* To use the Caikit-TGIS runtime, you have converted your model to Caikit format. For an example, see [Converting Hugging Face Hub models to Caikit format](https://github.com/opendatahub-io/caikit-tgis-serving/blob/main/demo/kserve/built-tip.md#bootstrap-process) in the [caikit-tgis-serving](https://github.com/opendatahub-io/caikit-tgis-serving/tree/main) repository.
* If you want to use graphics processing units (GPUs) with your model server, you have enabled GPU support in OpenShift AI. If you use NVIDIA GPUs, see [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai). If you use AMD GPUs, see [AMD GPU integration](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#amd-gpu-integration_managing-rhoai).
* To use the vLLM runtime, you have enabled GPU support in OpenShift AI and have installed and configured the Node Feature Discovery operator on your cluster. For more information, see [Installing the Node Feature Discovery operator](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator#installing-the-node-feature-discovery-operator_psap-node-feature-discovery-operator) and [Enabling NVIDIA GPUs](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/managing_openshift_ai/enabling_accelerators#enabling-nvidia-gpus_managing-rhoai).

**Procedure**

1. Open a command-line terminal and log in to your OpenShift cluster as cluster administrator:

   ```
   $ oc login <openshift_cluster_url> -u <admin_username> -p <password>
   ```
2. By default, OpenShift uses a service mesh for network traffic management. Because KServe raw deployment mode does not require a service mesh, disable Red Hat OpenShift Service Mesh:

   1. Enter the following command to disable Red Hat OpenShift Service Mesh:

      ```
      $ oc edit dsci -n redhat-ods-operator
      ```
   2. In the YAML editor, change the value of `managementState` for the `serviceMesh` component to `Removed` as shown:

      ```
      spec:
        components:
          serviceMesh:
            managementState: Removed
      ```
   3. Save the changes.
3. Create a project:

   ```
   $ oc new-project <project_name> --description="<description>" --display-name="<display_name>"
   ```

   For information about creating projects, see [Working with projects](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/building_applications/projects#working-with-projects).
4. Create a data science cluster:

   1. In the Red Hat OpenShift web console **Administrator** view, click **Operators** → **Installed Operators** and then click the Red Hat OpenShift AI Operator.
   2. Click the **Data Science Cluster** tab.
   3. Click the **Create DataScienceCluster** button.
   4. In the **Configure via** field, click the **YAML view** radio button.
   5. In the `spec.components` section of the YAML editor, configure the `kserve` component as shown:

      ```
        kserve:
          defaultDeploymentMode: RawDeployment
          managementState: Managed
          serving:
            managementState: Removed
            name: knative-serving
      ```
   6. Click **Create**.
5. Create a secret file:

   1. At your command-line terminal, create a YAML file to contain your secret and add the following YAML code:

      ```
      apiVersion: v1
      kind: Secret
      metadata:
        annotations:
          serving.kserve.io/s3-endpoint: <AWS_ENDPOINT>
          serving.kserve.io/s3-usehttps: "1"
          serving.kserve.io/s3-region: <AWS_REGION>
          serving.kserve.io/s3-useanoncredential: "false"
        name: <Secret-name>
      stringData:
        AWS_ACCESS_KEY_ID: "<AWS_ACCESS_KEY_ID>"
        AWS_SECRET_ACCESS_KEY: "<AWS_SECRET_ACCESS_KEY>"
      ```

      Important

      If you are deploying a machine learning model in a disconnected deployment, add `serving.kserve.io/s3-verifyssl: '0'` to the `metadata.annotations` section.
   2. Save the file with the file name **secret.yaml**.
   3. Apply the **secret.yaml** file:

      ```
      $ oc apply -f secret.yaml -n <namespace>
      ```
6. Create a service account:

   1. Create a YAML file to contain your service account and add the following YAML code:

      ```
      apiVersion: v1
      kind: ServiceAccount
      metadata:
        name: models-bucket-sa
      secrets:
      - name: s3creds
      ```

      For information about service accounts, see [Understanding and creating service accounts](https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/authentication_and_authorization/understanding-and-creating-service-accounts).
   2. Save the file with the file name **serviceAccount.yaml**.
   3. Apply the **serviceAccount.yaml** file:

      ```
      $ oc apply -f serviceAccount.yaml -n <namespace>
      ```
7. Create a YAML file for the serving runtime to define the container image that will serve your model predictions. Here is an example using the OpenVino Model Server:

   ```
   apiVersion: serving.kserve.io/v1alpha1
   kind: ServingRuntime
   metadata:
     name: ovms-runtime
   spec:
     annotations:
       prometheus.io/path: /metrics
       prometheus.io/port: "8888"
     containers:
       - args:
           - --model_name={{.Name}}
           - --port=8001
           - --rest_port=8888
           - --model_path=/mnt/models
           - --file_system_poll_wait_seconds=0
           - --grpc_bind_address=0.0.0.0
           - --rest_bind_address=0.0.0.0
           - --target_device=AUTO
           - --metrics_enable
         image: quay.io/modh/openvino_model_server@sha256:6c7795279f9075bebfcd9aecbb4a4ce4177eec41fb3f3e1f1079ce6309b7ae45
         name: kserve-container
         ports:
           - containerPort: 8888
             protocol: TCP
     multiModel: false
     protocolVersions:
       - v2
       - grpc-v2
     supportedModelFormats:
       - autoSelect: true
         name: openvino_ir
         version: opset13
       - name: onnx
         version: "1"
       - autoSelect: true
         name: tensorflow
         version: "1"
       - autoSelect: true
         name: tensorflow
         version: "2"
       - autoSelect: true
         name: paddle
         version: "2"
       - autoSelect: true
         name: pytorch
         version: "2"
   ```

   1. If you are using the OpenVINO Model Server example above, ensure that you insert the correct values required for any placeholders in the YAML code.
   2. Save the file with an appropriate file name.
   3. Apply the file containing your serving run time:

      ```
      $ oc apply -f <serving run time file name> -n <namespace>
      ```
8. Create an InferenceService custom resource (CR). Create a YAML file to contain the InferenceService CR. Using the OpenVINO Model Server example used previously, here is the corresponding YAML code:

   ```
   apiVersion: serving.kserve.io/v1beta1
   kind: InferenceService
   metadata:
     annotations:
       serving.knative.openshift.io/enablePassthrough: "true"
       sidecar.istio.io/inject: "true"
       sidecar.istio.io/rewriteAppHTTPProbers: "true"
       serving.kserve.io/deploymentMode: RawDeployment
     name: <InferenceService-Name>
   spec:
     predictor:
       scaleMetric:
       minReplicas: 1
       scaleTarget:
       canaryTrafficPercent:
       serviceAccountName: <serviceAccountName>
       model:
         env: []
         volumeMounts: []
         modelFormat:
           name: onnx
         runtime: ovms-runtime
         storageUri: s3://<bucket_name>/<model_directory_path>
         resources:
           requests:
             memory: 5Gi
       volumes: []
   ```

   1. In your YAML code, ensure the following values are set correctly:

      * `serving.kserve.io/deploymentMode` must contain the value `RawDeployment`.
      * `modelFormat` must contain the value for your model format, such as `onnx`.
      * `storageUri` must contain the value for your model s3 storage directory, for example `s3://<bucket_name>/<model_directory_path>`.
      * `runtime` must contain the value for the name of your serving runtime, for example, `ovms-runtime`.
   2. Save the file with an appropriate file name.
   3. Apply the file containing your InferenceService CR:

      ```
      $ oc apply -f <InferenceService CR file name> -n <namespace>
      ```
9. Verify that all pods are running in your cluster:

   ```
   $ oc get pods -n <namespace>
   ```

   Example output:

   ```
   NAME READY STATUS RESTARTS AGE
   <isvc_name>-predictor-xxxxx-2mr5l 1/1 Running 2 165m
   console-698d866b78-m87pm 1/1 Running 2 165m
   ```
10. After you verify that all pods are running, forward the service port to your local machine:

    ```
    $ oc -n <namespace> port-forward pod/<pod-name> <local_port>:<remote_port>
    ```

    Ensure that you replace `<namespace>`, `<pod-name>`, `<local_port>`, `<remote_port>` (this is the model server port, for example, `8888`) with values appropriate to your deployment.

**Verification**

* Use your preferred client library or tool to send requests to the `localhost` inference URL.

### [3.12. Deploying models by using the single-model serving platform](#deploying-models-using-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

On the single-model serving platform, each model is deployed on its own model server. This helps you to deploy, monitor, scale, and maintain large models that require increased resources.

Important

If you want to use the single-model serving platform to deploy a model from S3-compatible storage that uses a self-signed SSL certificate, you must install a certificate authority (CA) bundle on your OpenShift cluster. For more information, see [Working with certificates](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed/working-with-certificates_certs) (OpenShift AI Self-Managed) or [Working with certificates](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/installing_and_uninstalling_openshift_ai_self-managed_in_a_disconnected_environment/working-with-certificates_certs) (OpenShift AI Self-Managed in a disconnected environment).

#### [3.12.1. Enabling the single-model serving platform](#enabling-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

When you have installed KServe, you can use the Red Hat OpenShift AI dashboard to enable the single-model serving platform. You can also use the dashboard to enable model-serving runtimes for the platform.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You have installed KServe.
* Your cluster administrator has *not* edited the OpenShift AI dashboard configuration to disable the ability to select the single-model serving platform, which uses the KServe component. For more information, see [Dashboard configuration options](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16//html/managing_openshift_ai/customizing-the-dashboard#ref-dashboard-configuration-options_dashboard).

**Procedure**

1. Enable the single-model serving platform as follows:

   1. In the left menu, click **Settings** → **Cluster settings**.
   2. Locate the **Model serving platforms** section.
   3. To enable the single-model serving platform for projects, select the **Single-model serving platform** checkbox.
   4. Click **Save changes**.
2. Enable preinstalled runtimes for the single-model serving platform as follows:

   1. In the left menu of the OpenShift AI dashboard, click **Settings** → **Serving runtimes**.

      The **Serving runtimes** page shows preinstalled runtimes and any custom runtimes that you have added.

      For more information about preinstalled runtimes, see [Supported runtimes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#ref-supported-runtimes).
   2. Set the runtime that you want to use to **Enabled**.

      The single-model serving platform is now available for model deployments.

#### [3.12.2. Adding a custom model-serving runtime for the single-model serving platform](#adding-a-custom-model-serving-runtime-for-the-single-model-serving-platform_serving-large-models) Copy linkLink copied to clipboard!

A model-serving runtime adds support for a specified set of model frameworks and the model formats supported by those frameworks. You can use the [pre-installed runtimes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/serving_models/serving-large-models_serving-large-models#about-the-single-model-serving-platform_serving-large-models) that are included with OpenShift AI. You can also add your own custom runtimes if the default runtimes do not meet your needs. For example, if the TGIS runtime does not support a model format that is supported by [Hugging Face Text Generation Inference (TGI)](https://huggingface.co/docs/text-generation-inference/supported_models), you can create a custom runtime to add support for the model.

As an administrator, you can use the OpenShift AI interface to add and enable a custom model-serving runtime. You can then choose the custom runtime when you deploy a model on the single-model serving platform.

Note

Red Hat does not provide support for custom runtimes. You are responsible for ensuring that you are licensed to use any custom runtimes that you add, and for correctly configuring and maintaining them.

**Prerequisites**

* You have logged in to OpenShift AI as a user with OpenShift AI administrator privileges.
* You have built your custom runtime and added the image to a container image repository such as [Quay](https://quay.io).

**Procedure**

1. From the OpenShift AI dashboard, click **Settings** > **Serving runtimes**.

   The **Serving runtimes** page opens and shows the model-serving runtimes that are already installed and enabled.
2. To add a custom runtime, choose one of the following options:

   * To start with an existing runtime (for example, **TGIS Standalone ServingRuntime for KServe**), click the action menu (⋮) next to the existing runtime and then click **Duplicate**.
   * To add a new custom runtime, click **Add serving runtime**.
3. In the **Select the model serving platforms this runtime supports** list, select **Single-model serving platform**.
4. In the **Select the API protocol this runtime supports** list, select **REST** or **gRPC**.
5. Optional: If you started a new runtime (rather than duplicating an existing one), add your code by choosing one of the following options:

   * **Upload a YAML file**

     1. Click **Upload files**.
     2. In the file browser, select a YAML file on your computer.

        The embedded YAML editor opens and shows the contents of the file that you uploaded.
   * **Enter YAML code directly in the editor**

     1. Click **Start from scratch**.
     2. Enter or paste YAML code directly in the embedded editor.

   Note

   In many cases, creating a custom runtime will require adding new or custom parameters to the `env` section of the `ServingRuntime` specification.
6. Click **Add**.

   The **Serving runtimes** page opens and shows the updated list of runtimes that are installed. Observe that the custom runtime that you added is automatically enabled. The API protocol that you specified when creating the runtime is shown.