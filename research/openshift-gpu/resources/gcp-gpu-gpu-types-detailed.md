Source: https://cloud.google.com/compute/docs/gpus#gpu-options
Date: 2026-05-13
============================================================

->
Home
->
Documentation
->
Compute
->
Compute Engine
->
Guides
Send feedback
GPU machine types
Stay organized with collections
Save and categorize content based on your preferences.
This document outlines the NVIDIA GPU models that you can use to
accelerate machine learning (ML), data processing, and graphics-intensive
workloads on your Compute Engine instances. This
document also details which GPUs come pre-attached to accelerator-optimized
machine series such as A4X Max, A4X, A4, A3, A2, G4, and G2, and which GPUs you
can attach to N1 general-purpose instances.
Use this document to compare the performance, memory, and features of different
GPU models. For a more detailed overview of the accelerator-optimized machine
family, including information on CPU platforms, storage options, and networking
capabilities, and to find the specific machine type that matches your workload,
see  -> Accelerator-optimized machine family
.
For more information about GPUs on Compute Engine, see
-> About GPUs
.
To view available regions and zones for GPUs on Compute Engine, see
-> GPUs regions and zone availability
.
Overview
->
Compute Engine offers different machine types to support your various
workloads.
Some machine types support
-> NVIDIA RTX Virtual Workstations (vWS)
.
When you create an instance that uses NVIDIA RTX Virtual Workstation,
Compute Engine automatically adds a vWS license. For information about pricing
for virtual workstations, see the
-> GPU pricing page
.
GPU machine types
AI and ML workloads
Graphics and visualization
Other GPU workloads
Accelerator-optimized A series machine types
are designed for high
performance computing (HPC), artificial intelligence (AI), and machine
learning (ML) workloads.
The later generation A series are ideal for pre-training and fine-tuning
foundation models that involves large clusters of accelerators, while the A2
series can be used for training smaller models and single host inference.
For these machine types, the GPU model is automatically attached to the instance.
Accelerator-optimized G series machine types
are designed for workloads
such as NVIDIA Omniverse simulation workloads, graphics-intensive applications,
video transcoding, and virtual desktops. These machine types support
-> NVIDIA RTX Virtual Workstations (vWS)
.
The G series can also be used for training smaller models and for
single-host inference.
For these machine types, the GPU model is automatically attached to the instance.
For N1 general-purpose machine types, except for the N1 shared-core
(
f1-micro
and
g1-small
), you can attach a select
set of GPU models. Some of these GPU models also support NVIDIA RTX Virtual
Workstations (vWS).
-> A4X Max
(NVIDIA GB300 Ultra Superchips)
(
nvidia-gb300
)
-> A4X
(NVIDIA GB200 Superchips)
(
nvidia-gb200
)
-> A4
(NVIDIA B200)
(
nvidia-b200
)
-> A3 Ultra
(NVIDIA H200)
(
nvidia-h200-141gb
)
-> A3 Mega
(NVIDIA H100)
(
nvidia-h100-mega-80gb
)
-> A3 High
(NVIDIA H100)
(
nvidia-h100-80gb
)
-> A3 Edge
(NVIDIA H100)
(
nvidia-h100-80gb
)
-> A2 Ultra
(NVIDIA A100 80GB)
(
nvidia-a100-80gb
)
-> A2 Standard
(NVIDIA A100)
(
nvidia-a100-40gb
)
-> G4
(NVIDIA RTX PRO 6000)
(
nvidia-rtx-pro-6000
)
(
nvidia-rtx-pro-6000-vws
)
-> G2
(NVIDIA L4)
(
nvidia-l4
)
(
nvidia-l4-vws
)
The following GPU models can be attached to N1 general-purpose machine
types:
NVIDIA T4
(
nvidia-tesla-t4
)
(
nvidia-tesla-t4-vws
)
NVIDIA P4
(
nvidia-tesla-p4
)
(
nvidia-tesla-p4-vws
)
NVIDIA V100
(
nvidia-tesla-v100
)
NVIDIA P100
(
nvidia-tesla-p100
)
(
nvidia-tesla-p100-vws
)
You can also use some GPU machine types on
-> AI Hypercomputer
. AI Hypercomputer is a
supercomputing system that is optimized to support your artificial intelligence
(AI) and machine learning (ML) workloads. This option is recommended for creating a
densely allocated, performance-optimized infrastructure that has integrations
for Google Kubernetes Engine (GKE) and Slurm schedulers.
A4X Max and A4X machine series
The  -> A4X Max and A4X machine series
runs on an exascale platform based on
-> NVIDIA's rack-scale architecture
and is optimized for compute and memory-intensive, network-bound ML training and
HPC workloads. A4X Max and A4X differ primarily in their GPU and networking
components. A4X Max also offers bare metal instances, which provide
direct access to the host server's CPU and memory, without the Compute Engine
hypervisor layer.
A4X Max machine types (NVIDIA GB300)
-> A4X Max accelerator-optimized
machine types use NVIDIA GB300 Grace Blackwell Ultra Superchips (
nvidia-gb300
) and
are ideal for foundation model training and serving. A4X Max machine types are available
as  -> bare metal instances
.
A4X Max is an exascale platform based on
-> NVIDIA GB300
NVL72
. Each machine has two sockets with NVIDIA Grace CPUs with Arm
Neoverse V2 cores. These CPUs are connected to four NVIDIA B300 Blackwell GPUs with fast
chip-to-chip ( -> NVLink-C2C
)
communication.
->
Note:
When provisioning A4X Max instances, you
must  -> reserve capacity
to create instances
and clusters. You can then create instances that use the features and services available from
AI Hypercomputer. For more information, see
-> Deployment options overview
in
the AI Hypercomputer documentation.
Attached NVIDIA GB300 Grace Blackwell Ultra Superchips
Machine type
vCPU count
1
Instance memory (GB)
Attached Local SSD (GiB)
Physical NIC count
Maximum network bandwidth (Gbps)
2
GPU count
GPU memory
3
(GB HBM3e)
a4x-maxgpu-4g-metal
144
960
12,000
6
3,600
4
1,116
1
A vCPU is implemented as a single hardware hyper-thread on one of
the available  -> CPU platforms
.
2
Maximum egress bandwidth cannot exceed the number given. Actual
egress bandwidth depends on the destination IP address and other factors.
For more information about network bandwidth,
see  -> Network bandwidth
.
3
GPU memory is the memory on a GPU device that can be used for
temporary storage of data. It is separate from the instance's memory and is
specifically designed to handle the higher bandwidth demands of your
graphics-intensive workloads.
A4X machine type (NVIDIA GB200)
-> A4X accelerator-optimized
machine types use NVIDIA GB200 Grace Blackwell Superchips (
nvidia-gb200
) and
are ideal for foundation model training and serving.
A4X is an exascale platform based on
-> NVIDIA GB200
NVL72
. Each machine has two sockets with NVIDIA Grace CPUs with Arm
Neoverse V2 cores. These CPUs are connected to four NVIDIA B200 Blackwell GPUs with fast
chip-to-chip ( -> NVLink-C2C
)
communication.
->
Note:
When provisioning A4X instances, you
must  -> reserve capacity
to create instances
and clusters. You can then create instances that use the features and services available from
AI Hypercomputer. For more information, see
-> Deployment options overview
in
the AI Hypercomputer documentation.
Attached NVIDIA GB200 Grace Blackwell Superchips
Machine type
vCPU count
1
Instance memory (GB)
Attached Local SSD (GiB)
Physical NIC count
Maximum network bandwidth (Gbps)
2
GPU count
GPU memory
3
(GB HBM3e)
a4x-highgpu-4g
140
884
12,000
6
2,000
4
744
1
A vCPU is implemented as a single hardware hyper-thread on one of
the available  -> CPU platforms
.
2
Maximum egress bandwidth cannot exceed the number given. Actual
egress bandwidth depends on the destination IP address and other factors.
For more information about network bandwidth,
see  -> Network bandwidth
.
3
GPU memory is the memory on a GPU device that can be used for
temporary storage of data. It is separate from the instance's memory and is
specifically designed to handle the higher bandwidth demands of your
graphics-intensive workloads.
A4 machine series (NVIDIA B200)
-> A4 accelerator-optimized
machine types have
-> NVIDIA B200 Blackwell GPUs
(
nvidia-b200
) attached and are ideal for foundation model
training and serving.
->
Note:
When provisioning A4 machine types, you must
reserve capacity to create instances or clusters, use Spot VMs, use
Flex-start VMs, or create a resize request in a MIG. For instructions on how to create A4
instances, see
-> Create an A3 Ultra or A4 instance
.
Attached NVIDIA B200 Blackwell GPUs
Machine type
vCPU count
1
Instance memory (GB)
Attached Local SSD (GiB)
Physical NIC count
Maximum network bandwidth (Gbps)
2
GPU count
GPU memory
3
(GB HBM3e)
a4-highgpu-8g
224
3,968
12,000
10
3,600
8
1,440
1
A vCPU is implemented as a single hardware hyper-thread on one of
the available  -> CPU platforms
.
2
Maximum egress bandwidth cannot exceed the number given. Actual
egress bandwidth depends on the destination IP address and other factors.
For more information about network bandwidth, see
-> Network bandwidth
.
3
GPU memory is the memory on a GPU device that can be used for
temporary storage of data. It is separate from the instance's memory and is
specifically designed to handle the higher bandwidth demands of your
graphics-intensive workloads.
A3 machine series
-> A3 accelerator-optimized
machine types have NVIDIA H100 SXM or NVIDIA H200 SXM GPUs attached.
A3 Ultra machine type (NVIDIA H200)
-> A3 Ultra
machine types have  -> NVIDIA H200 SXM GPUs
(
nvidia-h200-141gb
) attached and provides the highest network
performance in the A3 series. A3 Ultra machine types are ideal for foundation model training and
serving.
->
Note:
When provisioning A3 Ultra machine
types, you must reserve capacity to create instances or clusters, use Spot VMs, use
Flex-start VMs, or create a resize request in a MIG. For more information about the
parameters to set when creating an A3 Ultra instance, see
-> Create an A3 Ultra or A4 instance
.
Attached NVIDIA H200 GPUs
Machine type
vCPU count
1
Instance memory (GB)
Attached Local SSD (GiB)
Physical NIC count
Maximum network bandwidth (Gbps)
2
GPU count
GPU memory
3
(GB HBM3e)
a3-ultragpu-8g
224
2,952
12,000
10
3,600
8
1128
1
A vCPU is implemented as a single hardware hyper-thread on one of
the available  -> CPU platforms
.
2
Maximum egress bandwidth cannot exceed the number given. Actual
egress bandwidth depends on the destination IP address and other factors.
For more information about network bandwidth,
see  -> Network bandwidth
.
3
GPU memory is the memory on a GPU device that can be used for
temporary storage of data. It is separate from the instance's memory and is
specifically designed to handle the higher bandwidth demands of your
graphics-intensive workloads.
A3 Mega, High, and Edge machine types (NVIDIA H100)
To use  -> NVIDIA H100 SXM GPUs
, you have the following options:
-> A3 Mega
: these machine types have H100 SXM GPUs (
nvidia-h100-mega-80gb
) and are ideal for large-scale training and serving workloads.
-> A3 High
: these machine types have H100 SXM GPUs (
nvidia-h100-80gb
) and are well-suited for both training and serving tasks.
-> A3 Edge
: these machine types have H100 SXM GPUs (
nvidia-h100-80gb
), are designed specifically for serving, and are available in a  -> limited set of regions
.
A3 Mega
->
Note:
When provisioning
a3-megagpu-8g
machine types, we recommend using a cluster of these instances and deploying
with a scheduler such as Google Kubernetes Engine (GKE) or Slurm. For detailed instructions on either of
these options, review the following:
To create Google Kubernetes Engine cluster, see
-> Deploy an A3 Mega cluster
with GKE
.
To create a Slurm cluster, see
-> Deploy an A3 Mega Slurm cluster
.
Attached NVIDIA H100 GPUs
Machine type
vCPU count
1
Instance memory (GB)
Attached Local SSD (GiB)
Physical NIC count
Maximum network bandwidth (Gbps)
2
GPU count
GPU memory
3
(GB HBM3)
a3-megagpu-8g
208
1,872
6,000
9
1,800
8
640
A3 High
->
Note:
When provisioning
a3-highgpu-1g
,
a3-highgpu-2g
, or
a3-highgpu-4g
machine types,
you must create instances by using Spot VMs or
Flex-start VMs. For detailed instructions on these options, review the following:
To create Spot VMs, set the provisioning model to
SPOT
when you
-> create an accelerator-optimized
VM
.
To create Flex-start VMs, you can use one of the following methods:
Create a standalone VM and set the provisioning model to
FLEX_START
when you
-> create an
accelerator-optimized VM
.
Create a resize request in a managed instance group (MIG). For instructions, see
-> Create a MIG with GPU
VMs
.
Attached NVIDIA H100 GPUs
Machine type
vCPU count
1
Instance memory (GB)
Attached Local SSD (GiB)
Physical NIC count
Maximum network bandwidth (Gbps)
2
GPU count
GPU memory
3
(GB HBM3)