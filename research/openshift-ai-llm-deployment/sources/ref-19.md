# Source: ref-19

**URL:** https://access.redhat.com/articles/rhoai-supported-configs
**Fetched:** 2026-04-17 17:54:34

---

This article lists the Red Hat OpenShift AI (RHOAI) 2.offerings (Self-Managed 2.x and Cloud Service), the RHOAI 2.x components, their current support phase, and their compatibility with the underlying platforms.

⚠️ ATTENTION: For Red Hat OpenShift AI 3.x go to the supported pages [HERE](https://access.redhat.com/articles/rhoai-supported-configs-3.x).

### Red Hat OpenShift AI Self-Managed

You install **OpenShift AI Self-Managed** by installing the Red Hat OpenShift AI Operator and then configuring the Operator to manage standalone components of the product.  
RHOAI Self-Managed is supported on OpenShift Container Platform running on x86\_64, ppc64le, s390x and aarch64 architectures. This includes the following providers:

* Bare Metal
* Hosted control planes on Bare Metal
* IBM Cloud
* Red Hat OpenStack
* Amazon Web Services
* Google Cloud Platform
* Microsoft Azure
* VMware vSphere
* Oracle Cloud
* IBM Power (Technology Preview)
* IBM Z (Technology Preview)

This also includes support for RHOAI Self-Managed on managed OpenShift offerings such as OpenShift Dedicated, Red Hat OpenShift Service on AWS (ROSA with HCP), Red Hat OpenShift Service on AWS (classic architecture), Microsoft Azure Red Hat OpenShift, and OpenShift Kubernetes Engine. Currently, RHOAI Self-Managed is not supported on OpenShift running on platforms such as MicroShift.  
For a full overview of the RHOAI Self-Managed life cycle and the currently supported releases, visit this [page](https://access.redhat.com/support/policy/updates/rhoai-sm/lifecycle).

**x86\_64 architecture**

| Operator Version |  |  |  |  |  |  |  | Components |  |  |  |  |  |  | OpenShift Version | Chipset Architecture |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | CodeFlare | Dashboard | Data science pipelines | Distributed Inference with llm-d | Feature Store | KServe | Kubeflow Training | Kuberay | Kueue | Red Hat Build of Kueue Operator | Llama Stack | Model Mesh Serving | Model Registry | TrustyAI | Workbenches |  |
| [2.25](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/index) | Deprecated | GA | GA | TP | TP | GA | Deprecated\* | GA | Deprecated | GA | TP | Deprecated | GA | GA | GA | 4.16, 4.17, 4.18, 4.19, 4.20 | x86\_64 |
| [2.22](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html/release_notes/index) | GA | GA | GA | - | TP | GA | GA | GA | GA | - | - | Deprecated | TP | GA | GA | 4.16, 4.17, 4.18, 4.19 | x86\_64 |
| [2.16](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.16/html/release_notes/index) | GA | GA | GA | - | - | GA | TP | GA | GA | - | - | GA | TP | GA | GA | 4.14, 4.16, 4.17, 4.18, 4.19 | x86\_64 |

\* Kubeflow v2 will release with 3.2 of RHOAI and replace the current version.

**ARM architecture**

| Operator Version | Components |  |  |  |  |  |  |  |  |  |  |  |  |  | OpenShift Version | Chipset Architecture |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | CodeFlare | Dashboard | Data science pipelines | Distributed Inference with llm-d | Feature Store | KServe | Kubeflow Training | Kuberay | Kueue | Red Hat Build of Kueue Operator | Llama Stack | Model Mesh Serving | Model Registry | TrustyAI | Workbenches |  |
| [2.25](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/index) | Deprecated | GA | GA | TP | TP\* | GA | Deprecated\*\* | GA | Deprecated | GA | TP | Deprecated | GA | GA | GA | 4.16, 4.17, 4.18, 4.19, 4.20 | aarch64 |

\* Only Intelligent Inference Routing is supported on aarch64 architecture.

\*\* Kubeflow v2 will release with 3.2 of RHOAI and replace the current version.

**IBM Z (s390x) architecture**

| Operator Version | Components |  |  |  |  |  |  |  |  |  |  |  |  |  | OpenShift Version | Chipset Architecture |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | CodeFlare | Dashboard | Data science pipelines | Distributed Inference with llm-d | Feature Store | KServe | Kubeflow Training | Kuberay | Kueue | Red Hat Build of Kueue Operator | Llama Stack | Model Mesh Serving | Model Registry | TrustyAI | Workbenches |  |
| [2.25](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/index) | Deprecated | TP | - | - | TP | TP | Deprecated\* | - | Deprecated | - | - | - | TP | TP | TP | 4.19 | s390x |
| [2.22](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html/release_notes/index) | - | TP | - | - | - | TP | - | - | - | - | - | - | - | - | - | 4.18, 4.19 | s390x |

\* Kubeflow v2 will release with 3.2 of RHOAI and replace the current version.

**IBM Power (ppc64le) architecture**

| Operator Version | Components |  |  |  |  |  |  |  |  |  |  |  |  |  | OpenShift Version | Chipset Architecture |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | CodeFlare | Dashboard | Data science pipelines | Distributed Inference with llm-d | Feature Store | KServe | Kubeflow Training | Kuberay | Kueue | Red Hat Build of Kueue Operator | Llama Stack | Model Mesh Serving | Model Registry | TrustyAI | Workbenches |  |
| [2.25](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/index) | Deprecated | TP | TP | - | TP | TP | Deprecated\* | - | Deprecated | TP | - | - | TP | TP | TP | 4.19 | ppc64le |
| [2.22](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.22/html/release_notes/index) | - | TP | - | - | - | TP | - | - | - | - | - | - | - | - | - | 4.18, 4.19 | ppc64le |

\* Kubeflow v2 will release with 3.2 of RHOAI and replace the current version.

### Red Hat OpenShift AI Cloud Service

You install **OpenShift AI Cloud Service** by installing the Red Hat OpenShift AI Add-on and then using the add-on to manage standalone components of the product. The add-on has a single version, reflecting the latest update of the cloud service.  
RHOAI Cloud Service is supported on OpenShift Dedicated (AWS and GCP) and on Red Hat OpenShift Service on AWS (classic architecture). Currently, RHOAI Cloud Service is not supported on Microsoft Azure Red Hat OpenShift and platform services such as ROSA with HCP.  
For a full overview of the RHOAI Cloud Service life cycle and the currently supported releases, visit this [page](https://access.redhat.com/support/policy/updates/rhoai-cs/lifecycle).

Note: 2.25 will be the last update for Red Hat OpenShift AI Cloud Service.

| Add-on Version | Components |  |  |  |  |  |  |  |  |  |  |  |  |  | OpenShift Version | Chipset Architecture |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
|  | CodeFlare | Dashboard | Data science pipelines | Distributed Inference with llm-d | Feature Store | KServe | Kubeflow Training | Kuberay | Kueue | Red Hat Build of Kueue Operator | Llama Stack | Model Mesh Serving | Model Registry | TrustyAI | Workbenches |  |
| [2.25](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/index) | Deprecated | GA | GA | TP | TP | GA | Deprecated\* | GA | Deprecated | GA | TP | Deprecated | GA | GA | GA | 4.16, 4.17, 4.18, 4.19, 4.20 | x86\_64 |

TP: [Technology Preview](https://access.redhat.com/support/offerings/techpreview/)  
DP: [Developer Preview](https://access.redhat.com/support/offerings/devpreview/)  
Developer and Technology Previews: [How they compare](https://access.redhat.com/articles/6966848)  
LA: Limited Availability. During this phase you can install and receive support for the feature only with specific approval from Red Hat. Without such approval, the feature is unsupported.  
GA: General Availability.  
EUS: Extended Update Support. During the EUS phase, Red Hat will maintain component specific support.  
EOL: End of Life. During this phase, the component will no longer be supported.

### RHOAI and vLLM version compatibility

The following table shows the version of the vLLM model-serving runtime that is included with each version of Red Hat OpenShift AI.

| RHOAI Version | vLLM CUDA | vLLM ROCm | vLLM Power/Z | vLLM Gaudi |
| --- | --- | --- | --- | --- |
| RHOAI-2.25 | v0.10.1.1 | v0.10.1.1 | v0.10.1.1.6 | v0.8.5+Gaudi-1.21.3 |
| RHOAI-2.22 | v0.9.1.0 | v0.8.4.3 | v0.9.1.0 | v0.7.2+Gaudi-1.21.0 |
| RHOAI-2.16 | v0.6.3.post1 | v0.6.3.post1 |  | v0.6.6.post1+Gaudi-1.20.0 |

### RHOAI and Distributed Inference with llm-d compatibility

The following table shows the version of the llm-d that is included with each version of Red Hat OpenShift AI.

| RHOAI Version | llm-d | Status |
| --- | --- | --- |
| RHOAI-3.0 | v0.2 | [Technology Preview](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/technology-preview-features_relnotes) |
| RHOAI-2.25 | v0.2 | [Technology Preview](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.25/html/release_notes/technology-preview-features_relnotes) |

### RHOAI: Distributed Inference with llm-d Supported Hardware

**NVIDIA**

| `llm-d` Well-Lit Path | Primary Goal | NVIDIA Hardware | Networking Requirement | Storage Requirement |
| --- | --- | --- | --- | --- |
| **Intelligent Inference Scheduling** | Route requests to the most optimal GPU. | H100, H200, B200, A100 | Standard DC Ethernet (25/100 GbE) | Local SSD (NVMe Recommended) |
| **P/D Disaggregation** | Separate prefill and decode compute stages. | H100, H200, B200 | High-Speed Ethernet (100 GbE) | Local SSD (NVMe Recommended) |
| **KV Cache Management (N/S Offloading)** | Increase throughput by offloading KV cache to CPU RAM. | H100, H200, B200, A100 | Standard DC Ethernet (25/100 GbE) | High-speed NVMe SSDs |
| **Wide Expert Parallelism (WEP)** | Distribute MoE models across many GPUs. | H100, H200, B200 | HPC Fabric with RDMA: InfiniBand, RoCE | High-speed NVMe SSDs |

**AMD**

| `llm-d` Well-Lit Path | Primary Goal | AMD Hardware | Networking Requirement | Storage Requirement |
| --- | --- | --- | --- | --- |
| **Intelligent Inference Scheduling** | Route requests to the most optimal GPU. | MI300X | Standard DC Ethernet (25/100 GbE) | Local SSD (NVMe Recommended) |
| **P/D Disaggregation** | Separate prefill and decode compute stages. | **Unsupported.** | Not Applicable | Not Applicable |
| **KV Cache Management (N/S Offloading)** | Increase throughput by offloading KV cache to CPU RAM. | MI300X | Standard DC Ethernet (25/100 GbE) | Local SSD (NVMe Recommended) |
| **Wide Expert Parallelism (WEP)** | Distribute MoE models across many GPUs. | **Unsupported.** | Not Applicable | Not Applicable |

**Red Hat OpenShift AI Operator Dependencies**

For information on the compatibility and supported versions of Red Hat OpenShift AI Operator dependencies, see the following documentation:

* Red Hat OpenShift Serverless: [release notes](https://docs.redhat.com/en/documentation/red_hat_openshift_serverless/latest/html/about_openshift_serverless/serverless-release-notes)
* Red Hat OpenShift Service Mesh: [release notes](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/service_mesh/service-mesh-2-x#making-open-source-more-inclusive_ossm-release-notes)
* Node Feature Discovery Operator: [documentation](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/specialized_hardware_and_driver_enablement/psap-node-feature-discovery-operator)
* Red Hat - Authorino Operator: [documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#installing-the-authorino-operator_component-install)
* NVIDIA GPU Operator: [documentation](https://access.redhat.com/bounce/?externalURL=hhttps%3A%2F%2Fdocs.nvidia.com%2Fdatacenter%2Fcloud-native%2Fopenshift%2Flatest%2Findex.html)
* Intel Gaudi Base Operator: [documentation](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fdocs.habana.ai%2Fen%2Flatest%2FSupport_Matrix%2FSupport_Matrix.html)
* AMD GPU Operator: [documentation](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Finstinct.docs.amd.com%2Fprojects%2Fgpu-operator%2Fen%2Flatest%2F)
* NVIDIA Network Operator: [documentation](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fdocs.nvidia.com%2Fnetworking%2Fdisplay%2Fkubernetes2470%2Fgetting-started-openshift.html)
* Red Hat Connectivity Link: [release notes](https://docs.redhat.com/en/documentation/red_hat_connectivity_link/1.2)
* IBM Spyre Operator : [documentation](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fwww.ibm.com%2Fdocs%2Fen%2Frhocp-ibm-z%3Ftopic%3Dspyre-operator-z-linuxone)

Currently, OpenShift Service Mesh v3 is not supported.

Currently, Red Hat - Authorino Operator is the only Red Hat Connectivity Link component that is supported in Red Hat OpenShift AI. To install or upgrade the Red Hat - Authorino Operator, follow the instructions in the [Red Hat OpenShift AI documentation](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/installing_and_uninstalling_openshift_ai_self-managed/installing-the-single-model-serving-platform_component-install#installing-the-authorino-operator_component-install).

In Red Hat OpenShift AI, the CodeFlare Operator is included in the base product and not in a separate Operator. Separately installed instances of the CodeFlare Operator from Red Hat or the community are not supported. For more information, see the Red Hat Knowledgebase solution [How to migrate from a separately installed CodeFlare Operator in your data science cluster](https://access.redhat.com/solutions/7043796).

Red Hat OpenShift AI does not directly support any specific accelerators. To use accelerator functionality in OpenShift AI, the relevant accelerator Operators are required. OpenShift AI supports integration with the relevant Operators, and provides many images across the product that include the libraries to work with NVIDIA GPUs, AMD GPUs, Intel Gaudi AI accelerators and IBM Spyre. For more information about which devices are supported by an Operator, see the documentation for that Operator.

### Support requirements and limitations

Review this section to understand the requirements for Red Hat support and any limitations to Red Hat support of Red Hat OpenShift AI.

**Supported browsers**

* Google Chrome
* Mozilla Firefox
* Safari

**Supported services**

Red Hat OpenShift AI supports the following services:

| Service Name | Description |
| --- | --- |
| EDB Postgres AI - solution including Pgvector | Use powerful hybrid search for AI RAG and multimodal AI recommender applications with EDB's vector database solution including Pgvector. Combine AI, transactional, and analytical workloads with native vector index search, enterprise-grade security, and scalability in a unified Postgres environment. |
| Elasticsearch | Build transformative RAG applications, proactively resolve observability issues, and address complex security threats — all with the power of Search AI. |
| IBM Watson Studio | IBM® watsonx.ai is part of the IBM watsonx AI and data platform, bringing together new generative AI capabilities powered by foundation models and traditional machine learning (ML) into a powerful studio spanning the AI lifecycle. |
| Intel® oneAPI AI Analytics Toolkit Container | The AI Kit is a set of AI software tools to accelerate end-to-end data science and analytics pipelines on Intel® architectures. |
| NVIDIA NIM | NVIDIA NIM, part of NVIDIA AI Enterprise, is a set of easy-to-use microservices designed for secure, reliable deployment of high-performance AI model inferencing across the cloud, data center and workstations. Supporting a wide range of AI models, including open-source community and NVIDIA AI Foundation models, it ensures seamless, scalable AI inferencing, on-premises or in the cloud, leveraging industry standard APIs. |
| OpenVINO | OpenVINO is an open source toolkit to help optimize deep learning performance and deploy using an inference engine onto Intel® hardware. |
| Pachyderm | Pachyderm is the data foundation for machine learning. It provides industry-leading pipelines, data versioning, and lineage for data science teams to automate the machine learning lifecycle. |
| Starburst Enterprise | Starburst Enterprise platform (SEP) is the commericial distribution of Trino, which is an open-source, Massively Parallel Processing (MPP) ANSI SQL query engine. Starburst simplifies data access for your Red Hat OpenShift AI workloads by providing fast access to all of your data, no matter where it lives. Starburst does this by connecting directly to each data source and pulling the data back into memory for processing, alleviating the need to copy or move the data into a single location first. |
| Jupyter | Jupyter is a multi-user version of the notebook designed for companies, classrooms, and research labs. |

**Supported workbench images**

The latest supported workbench images in Red Hat OpenShift AI are installed with Python by default.  
You can install packages that are compatible with the supported version of Python on any workbench server that has the binaries required by that package. If the required binaries are not included on the workbench image you want to use, contact Red Hat Support to request that the binary be considered for inclusion.

To provide a consistent, stable platform for your model development, select workbench images that contain the same version of Python. Workbench images available on OpenShift AI are pre-built and ready for you to use immediately after OpenShift AI is installed or upgraded.  
Workbench images are supported for a minimum of one year. Major updates to pre-configured workbench images occur about every six months. Therefore, two supported workbench image versions are typically available at any given time. You can use this support period to update your code to use components from the latest available workbench image. Legacy workbench image versions, that is, not the two most recent versions, might still be available for selection. Legacy image versions include a label that indicates the image is out-of-date. To use the latest package versions, Red Hat recommends that you use the most recently added workbench image. If necessary, you can still access older workbench images from the registry, even if they are no longer supported. You can then add the older workbench images as custom workbench images to cater for your project’s specific requirements.

Workbench images denoted with *Technology Preview* in the following table are not supported with Red Hat production service level agreements (SLAs) and might not be functionally complete. Red Hat does not recommend using [Technology Preview](https://access.redhat.com/support/offerings/techpreview/) features in production. These features provide early access to upcoming product features, enabling customers to test functionality and provide feedback during the development process.

| Image name | Image version | Preinstalled packages |
| --- | --- | --- |
| Code Server | Data Science | CPU | Python 3.12 | 2025.2 (Recommended) | code-server 4.104, Python 3.12, Boto3: 1.40, Kafka-Python-ng: 2.2, Matplotlib: 3.10, Numpy: 2.3, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Sklearn-onnx: 1.19, ipykernel: 6.30, Kubeflow-Training: 1.9 |
|  | 2025.1 | code-server 4.98, Python 3.11, Boto3: 1.37, Kafka-Python-ng: 2.2, Matplotlib: 3.10, Numpy: 2.2, Pandas: 2.2, Scikit-learn: 1.6, Scipy: 1.15, Sklearn-onnx: 1.18, ipykernel: 6.29, Kubeflow-Training: 1.9 |
| Jupyter | Data Science | CPU | Python 3.12 | 2025.2 (Recommended) | Python 3.12, JupyterLab: 4.4, Boto3: 1.40, Kafka-Python-ng: 2.2, Kfp: 2.14, Matplotlib: 3.10, Numpy: 2.3, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Feast: 0.53, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4, Kubeflow-Training: 1.9 |
|  | 2025.1 | Python 3.11, JupyterLab: 4.4, Boto3: 1.37, Kafka-Python-ng: 2.2, Kfp: 2.12, Matplotlib: 3.10, Numpy: 2.2, Pandas: 2.2, Scikit-learn: 1.6, Scipy: 1.15, Odh-Elyra: 4.2, PyMongo: 4.11, Pyodbc: 5.2, Codeflare-SDK: 0.30, Sklearn-onnx: 1.18, Psycopg: 3.2, MySQL Connector/Python: 9.3, Kubeflow-Training: 1.9 |
| Jupyter | Minimal | CPU | Python 3.12 | 2025.2 (Recommended) | Python 3.12, JupyterLab: 4.4 |
|  | 2025.1 | Python 3.11, JupyterLab: 4.4 |
| Jupyter | Minimal | CUDA | Python 3.12 | 2025.2 (Recommended) | CUDA 12.8, Python 3.12, JupyterLab: 4.4 |
|  | 2025.1 | CUDA 12.6, Python 3.11, JupyterLab: 4.4 |
| Jupyter | Minimal | ROCm | Python 3.12 | 2025.2 (Recommended) | ROCm 6.2, Python 3.12, JupyterLab: 4.4 |
|  | 2025.1 | ROCm 6.2, Python 3.11, JupyterLab: 4.4 |
| Jupyter | PyTorch LLM Compressor | CUDA | Python 3.12 | 2025.2 | CUDA 12.8, Python 3.12, JupyterLab: 4.4, PyTorch: 2.7, LLM-Compressor: 0.7, Tensorboard: 2.20, Boto3: 1.40, Kafka-Python-ng: 2.2, Kfp: 2.14, Matplotlib: 3.10, Numpy: 2.2, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Feast: 0.53, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4, Kubeflow-Training: 1.9 |
| Jupyter | PyTorch | CUDA | Python 3.12 | 2025.2 (Recommended) | CUDA 12.8, Python 3.12, JupyterLab: 4.4, PyTorch: 2.7, Tensorboard: 2.20, Boto3: 1.40, Kafka-Python-ng: 2.2, Kfp: 2.14, Matplotlib: 3.10, Numpy: 2.3, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Feast: 0.53, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4, Kubeflow-Training: 1.9 |
|  | 2025.1 | CUDA 12.6, Python 3.11, JupyterLab: 4.4, PyTorch: 2.6, Tensorboard: 2.19, Boto3: 1.37, Kafka-Python-ng: 2.2, Kfp: 2.12, Matplotlib: 3.10, Numpy: 2.2, Pandas: 2.2, Scikit-learn: 1.6, Scipy: 1.15, Odh-Elyra: 4.2, PyMongo: 4.11, Pyodbc: 5.2, Codeflare-SDK: 0.30, Sklearn-onnx: 1.18, Psycopg: 3.2, MySQL Connector/Python: 9.3, Kubeflow-Training: 1.9 |
| Jupyter | PyTorch | ROCm | Python 3.12 | 2025.2 (Recommended) | ROCm 6.4, Python 3.12, JupyterLab: 4.4, ROCm-PyTorch: 2.7, Tensorboard: 2.20, Kafka-Python-ng: 2.2, Matplotlib: 3.10, Numpy: 2.3, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Feast: 0.53, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4, Kubeflow-Training: 1.9 |
|  | 2025.1 | ROCm 6.2, Python 3.11, JupyterLab: 4.4, ROCm-PyTorch: 2.6, Tensorboard: 2.18, Kafka-Python-ng: 2.2, Matplotlib: 3.10, Numpy: 2.2, Pandas: 2.2, Scikit-learn: 1.6, Scipy: 1.15, Odh-Elyra: 4.2, PyMongo: 4.11, Pyodbc: 5.2, Codeflare-SDK: 0.30, Sklearn-onnx: 1.18, Psycopg: 3.2, MySQL Connector/Python: 9.3, Kubeflow-Training: 1.9 |
| Jupyter | TensorFlow | CUDA | Python 3.12 | 2025.2 (Recommended) | CUDA 12.8, Python 3.12, JupyterLab: 4.4, TensorFlow: 2.20, Tensorboard: 2.20, Nvidia-CUDA-CU12-Bundle: 12.9, Boto3: 1.40, Kafka-Python-ng: 2.2, Kfp: 2.14, Matplotlib: 3.10, Numpy: 2.1, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Feast: 0.53, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4 |
|  | 2025.1 | CUDA 12.6, Python 3.11, JupyterLab: 4.4, TensorFlow: 2.18, Tensorboard: 2.18, Nvidia-CUDA-CU12-Bundle: 12.5, Boto3: 1.37, Kafka-Python-ng: 2.2, Kfp: 2.12, Matplotlib: 3.10, Numpy: 1.26, Pandas: 2.2, Scikit-learn: 1.6, Scipy: 1.15, Odh-Elyra: 4.2, PyMongo: 4.11, Pyodbc: 5.2, Codeflare-SDK: 0.30, Sklearn-onnx: 1.18, Psycopg: 3.2, MySQL Connector/Python: 9.3 |
| Jupyter | TensorFlow | ROCm | Python 3.12 | 2025.2 (Recommended) | ROCm 6.4, Python 3.12, JupyterLab: 4.4, TensorFlow-ROCm: 2.18, Tensorboard: 2.18, Kafka-Python-ng: 2.2, Matplotlib: 3.10, Numpy: 2.0, Pandas: 2.3, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Feast: 0.53, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4 |
|  | 2025.1 | ROCm 6.2, Python 3.11, JupyterLab: 4.4, TensorFlow-ROCm: 2.14, Tensorboard: 2.14, Kafka-Python-ng: 2.2, Matplotlib: 3.10, Numpy: 1.26, Pandas: 2.2, Scikit-learn: 1.6, Scipy: 1.15, Odh-Elyra: 4.2, PyMongo: 4.11, Pyodbc: 5.2, Codeflare-SDK: 0.30, Sklearn-onnx: 1.17, Psycopg: 3.2, MySQL Connector/Python: 9.3 |
| Jupyter | TrustyAI | CPU | Python 3.12 | 2025.2 (Recommended) | Python 3.12, JupyterLab: 4.4, TrustyAI: 0.6, Transformers: 4.56, Datasets: 4.0, Accelerate: 1.10, Torch: 2.7, Boto3: 1.40, Kafka-Python-ng: 2.2, Kfp: 2.14, Matplotlib: 3.10, Numpy: 1.26, Pandas: 1.5, Scikit-learn: 1.7, Scipy: 1.16, Odh-Elyra: 4.2, PyMongo: 4.14, Pyodbc: 5.2, Codeflare-SDK: 0.31, Sklearn-onnx: 1.19, Psycopg: 3.2, MySQL Connector/Python: 9.4, Kubeflow-Training: 1.9 |
|  | 2025.1 | Python 3.11, JupyterLab: 4.4, TrustyAI: 0.6, Transformers: 4.55, Datasets: 3.4, Accelerate: 1.5, Torch: 2.6, Boto3: 1.37, Kafka-Python-ng: 2.2, Kfp: 2.12, Matplotlib: 3.10, Numpy: 1.26, Pandas: 1.5, Scikit-learn: 1.7, Scipy: 1.15, Odh-Elyra: 4.2, PyMongo: 4.11, Pyodbc: 5.2, Codeflare-SDK: 0.29, Sklearn-onnx: 1.18, Psycopg: 3.2, MySQL Connector/Python: 9.3, Kubeflow-Training: 1.9 |

**Supported model-serving runtimes**

| Runtime name | Description | Exported model format |
| --- | --- | --- |
| vLLM Spyre AI Accelerator ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime that supports IBM Spyre AI accelerators on x86 | [Supported models](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2Fvllm-project%2Fvllm-spyre%2Fblob%2Fmain%2Fdocs%2Fuser_guide%2Fsupported_models.md) |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe (1) | A composite runtime for serving models in the Caikit format | Caikit Text Generation |
| Caikit Standalone ServingRuntime for KServe (2) | A runtime for serving models in the Caikit embeddings format for embeddings tasks | Caikit Embeddings |
| OpenVINO Model Server | A scalable, high-performance runtime for serving models that are optimized for Intel architectures | PyTorch, TensorFlow, OpenVINO IR, PaddlePaddle, MXNet, Caffe, Kaldi |
| [Deprecated] Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe (3) | A runtime for serving TGI-enabled models | PyTorch Model Formats |
| vLLM NVIDIA GPU ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime for large language models that supports NVIDIA GPU accelerators | [Supported models](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fdocs.vllm.ai%2Fen%2Flatest%2Fmodels%2Fsupported_models.html) |
| vLLM Intel Gaudi Accelerator ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime that supports Intel Gaudi accelerators | [Supported models](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fdocs.vllm.ai%2Fen%2Flatest%2Fmodels%2Fsupported_models.html) |
| vLLM AMD GPU ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime that supports AMD GPU accelerators | [Supported models](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fdocs.vllm.ai%2Fen%2Flatest%2Fmodels%2Fsupported_models.html) |
| CPU ServingRuntime for KServe | A high-throughput and memory-efficient inference and serving runtime that supports IBM Power (ppc64le) and IBM Z (s390x) | [Supported models](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fdocs.vllm.ai%2Fen%2Flatest%2Fmodels%2Fsupported_models.html) |

(1) The composite Caikit-TGIS runtime is based on [Caikit](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2Fopendatahub-io%2Fcaikit) and [Text Generation Inference Server (TGIS)](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2FIBM%2Ftext-generation-inference). To use this runtime, you must convert your models to Caikit format. For an example, see [Converting Hugging Face Hub models to Caikit format](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2Fopendatahub-io%2Fcaikit-tgis-serving%2Fblob%2Fmain%2Fdemo%2Fkserve%2Fbuilt-tip.md%23bootstrap-process) in the [caikit-tgis-serving](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2Fopendatahub-io%2Fcaikit-tgis-serving%2Ftree%2Fmain) repository.

(2) The Caikit Standalone runtime is based on [Caikit NLP](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2Fcaikit%2Fcaikit-nlp%2Ftree%2Fmain). To use this runtime, you must convert your models to the Caikit embeddings format. For an example, see [Tests for text embedding module](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fgithub.com%2Fcaikit%2Fcaikit-nlp%2Fblob%2Fmain%2Ftests%2Fmodules%2Ftext_embedding%2Ftest_embedding.py).

(3) The *Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe* is deprecated. For more information, see [Red Hat OpenShift AI release notes](https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/latest/html/release_notes/).

**Deployment requirements for supported model-serving runtimes**

| Runtime name | Default protocol | Additonal protocol | Model mesh support | Single node OpenShift support | Deployment mode |
| --- | --- | --- | --- | --- | --- |
| vLLM Spyre AI Accelerator ServingRuntime for KServe | REST | No | No | Yes | Raw and serverless |
| Caikit Text Generation Inference Server (Caikit-TGIS) ServingRuntime for KServe | REST | gRPC | No | Yes | Raw and serverless |
| Caikit Standalone ServingRuntime for KServe | REST | gRPC | No | Yes | Raw and serverless |
| OpenVINO Model Server | REST | None | Yes | Yes | Raw and serverless |
| [Deprecated] Text Generation Inference Server (TGIS) Standalone ServingRuntime for KServe | gRPC | None | No | Yes | Raw and serverless |
| vLLM NVIDIA GPU ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM Intel Gaudi Accelerator ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM AMD GPU ServingRuntime for KServe | REST | None | No | Yes | Raw and serverless |
| vLLM CPU ServingRuntime for KServe (1) | REST | None | No | Yes | Raw |

(1) For vLLM CPU ServingRuntime for KServe, if you are using IBM Z and IBM Power architecture, you can only deploy models in standard deployment mode.

**Tested and verified model-serving runtimes**

| Name | Description | Exported model format |
| --- | --- | --- |
| NVIDIA Triton Inference Server | An open-source inference-serving software for fast and scalable AI in applications. | TensorRT, TensorFlow, PyTorch, ONNX, OpenVINO, Python, RAPIDS FIL, and more |
| Seldon MLServer | An open-source inference server designed to simplify the deployment of machine learning models. | Scikit-Learn (sklearn), XGBoost, LightGBM, CatBoost, HuggingFace and MLflow |

**Deployment requirements for tested and verified model-serving runtimes**

| Name | Default protocol | Additional protocol | Model mesh support | Single node OpenShift support | Deployment mode |
| --- | --- | --- | --- | --- | --- |
| NVIDIA Triton Inference Server | gRPC | REST | Yes | Yes | Standard and advanced |
| Seldon MLServer | gRPC | REST | No | Yes | Standard and advanced |

**Note:** The `alibi-detect` and `alibi-explain` libraries from Seldon are under the Business Source License 1.1 (BSL 1.1). These libraries are not tested, verified, or supported by {org-name} as part of the certified *Seldon MLServer* runtime. It is not recommended that you use these libraries in production environments with the runtime.

**Training images**

To run distributed training jobs in OpenShift AI, you can use one of the following types of training image:

* A Ray-based training image that is tested and verified for the documented use cases and configurations
* A training image that Red Hat supports for use with the Kubeflow Training Operator (KFTO)

**Ray-based training images**

The following table provides information about the latest available Ray-based training images in Red Hat OpenShift AI. These images are AMD64 images, which might not work on other architectures.

You can use the provided images as base images, and install additional packages to create custom images, as described in the product documentation. If the required packages are not included in the training image you want to use, contact Red Hat Support to request that the package be considered for inclusion.

The images are updated periodically with new versions of the installed packages. These images have been tested and verified for the use cases and configurations that are documented in the corresponding product documentation. Bug fixes and CVE fixes are delivered after they are available in upstream packages, in newer versions of these images only; fixes are not backported to earlier image versions.

| Image type | RHOAI version | Image version | URL | Preinstalled packages |
| --- | --- | --- | --- | --- |
| CUDA | 2.25 | 2.47.1-py312-cu128 | [quay.io/modh/ray:2.47.1-py312-cu128](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Frepository%2Fmodh%2Fray%3Ftab%3Dtags%26tag%3D2.47.1-py312-cu128) | Ray 2.47.1, CUDA 12.8, Python 3.12 |
|  |  | 2.47.1-py311-cu121 | [quay.io/modh/ray:2.47.1-py311-cu121](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Frepository%2Fmodh%2Fray%3Ftab%3Dtags%26tag%3D2.47.1-py311-cu121) | Ray 2.47.1, CUDA 12.1, Python 3.11 |
|  | 2.22 | 2.46.0-py311-cu121 | [quay.io/modh/ray:2.46.0-py311-cu121](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Frepository%2Fmodh%2Fray%3Ftab%3Dtags%26tag%3D2.46.0-py311-cu121) | Ray 2.46.0, CUDA 12.1, Python 3.11 |
|  | 2.16 | 2.35.0-py311-cu121 | [quay.io/modh/ray:2.35.0-py311-cu121](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Fray%3A2.35.0-py311-cu121) | Ray 2.35, CUDA 12.1, Python 3.11 |
|  |  | 2.35.0-py39-cu121 | [quay.io/modh/ray:2.35.0-py39-cu121](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Fray%3A2.35.0-py39-cu121) | Ray 2.35, CUDA 12.1, Python 3.9 |
| Ray ROCm | 2.25 | 2.47.1-py312-rocm62 | [quay.io/modh/ray:2.47.1-py312-rocm62](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Frepository%2Fmodh%2Fray%3Ftab%3Dtags%26tag%3D2.47.1-py312-rocm62) | Ray 2.47.1, ROCm 6.2, Python 3.12 |
|  | 2.22 | 2.46.0-py311-rocm62 | [quay.io/modh/ray:2.46.0-py311-rocm62](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Frepository%2Fmodh%2Fray%3Ftab%3Dtags%26tag%3D2.46.0-py311-rocm62) | Ray 2.46.0, ROCm 6.2, Python 3.11 |
|  |  | 2.35.0-py39-rocm62 | [quay.io/modh/ray:2.35.0-py39-rocm62](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Fray%3A2.35.0-py39-rocm62) | Ray 2.35, ROCm 6.2, Python 3.9 |
|  | 2.16 | 2.35.0-py311-rocm61 | [quay.io/modh/ray:2.35.0-py311-rocm61](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Fray%3A2.35.0-py311-rocm61) | Ray 2.35, ROCm 6.1, Python 3.11 |
|  |  | 2.35.0-py39-rocm61 | [quay.io/modh/ray:2.35.0-py39-rocm61](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Fray%3A2.35.0-py39-rocm61) | Ray 2.35, ROCm 6.1, Python 3.9 |

**Training images for use with KFTO**

The following table provides information about the training images that Red Hat supports for use with the Kubeflow Training Operator (KFTO) in Red Hat OpenShift AI. These images are AMD64 images, which might not work on other architectures.

You can use the provided images as base images, and install additional packages to create custom images, as described in the product documentation.

| Image type | RHOAI version | Image version | URL | Preinstalled packages |
| --- | --- | --- | --- | --- |
| CUDA | 2.25 | py311-cuda124-torch251 | [registry.redhat.io/rhoai/odh-training-py311-cuda124-torch251](https://catalog.redhat.com/en/software/containers/rhoai/odh-training-cuda124-torch25-py311-rhel9/68ee46d4dd09ffc4be6701c4) | CUDA 12.4, Python 3.11, PyTorch 2.5.1 |
|  |  | py311-cuda121-torch241 | [registry.redhat.io/rhoai/odh-training-py311-cuda121-torch241](https://catalog.redhat.com/en/software/containers/rhoai/odh-training-cuda121-torch24-py311-rhel9/68ee46d3988a3daf777a112a) | CUDA 12.1, Python 3.11, PyTorch 2.4.1 |
|  | 2.16, 2.22 | py311-cuda124-torch251 | [quay.io/modh/training:py311-cuda124-torch251](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Ftraining%3Apy311-cuda124-torch251) | CUDA 12.4, Python 3.11, PyTorch 2.5.1 |
|  |  | py311-cuda121-torch241 | [quay.io/modh/training:py311-cuda121-torch241](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Ftraining%3Apy311-cuda121-torch241) | CUDA 12.1, Python 3.11, PyTorch 2.4.1 |
| ROCm | 2.25 | py311-rocm62-torch251 | [registry.redhat.io/rhoai/odh-training-py311-rocm62-torch251](https://catalog.redhat.com/en/software/containers/rhoai/odh-training-rocm62-torch25-py311-rhel9/68ee46d5017c46a5193a05dd) | ROCm 6.2, Python 3.11, PyTorch 2.5.1 |
|  |  | py311-rocm62-torch241 | [registry.redhat.io/rhoai/odh-training-py311-rocm62-torch241](https://catalog.redhat.com/en/software/containers/rhoai/odh-training-rocm62-torch24-py311-rhel9/68ee46d5017c46a5193a05d8) | ROCm 6.2, Python 3.11, PyTorch 2.4.1 |
|  | 2.16, 2.22 | py311-rocm62-torch251 | [quay.io/modh/training:py311-rocm62-torch251](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Ftraining%3Apy311-rocm62-torch251) | ROCm 6.2, Python 3.11, PyTorch 2.5.1 |
|  |  | py311-rocm62-torch241 | [quay.io/modh/training:py311-rocm62-torch241](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Ftraining%3Apy311-rocm62-torch241) | ROCm 6.2, Python 3.11, PyTorch 2.4.1 |
|  | 2.16 | py311-rocm61-torch241 | [quay.io/modh/training:py311-rocm61-torch241](https://access.redhat.com/bounce/?externalURL=https%3A%2F%2Fquay.io%2Fmodh%2Ftraining%3Apy311-rocm61-torch241) | ROCm 6.1, Python 3.11, PyTorch 2.4.1 |

* **Product(s)**
* [Red Hat OpenShift AI](https://access.redhat.com/search?q=Red+Hat+OpenShift+AI&documentKind=Article%26Solution)

* **Category**
* [Supportability](https://access.redhat.com/search?q=Supportability&documentKind=Article%26Solution)

* **Tags**
* [ai](https://access.redhat.com/search?q=ai&documentKind=Article%26Solution)
* [openshift\_data\_science](https://access.redhat.com/search?q=openshift_data_science&documentKind=Article%26Solution)
* [rhoai-self-managed](https://access.redhat.com/search?q=rhoai-self-managed&documentKind=Article%26Solution)

* **Article Type**
* [General](https://access.redhat.com/search?q=General&documentKind=Article%26Solution)

## Comments