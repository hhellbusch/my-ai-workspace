# Source: ref-36

**URL:** https://developers.redhat.com/cheat-sheets/openshift-disconnected-installation-cheat-sheet
**Fetched:** 2026-04-17 (WebFetch fallback)

---

# OpenShift disconnected installation cheat sheet

March 4, 2025 (downloadable cheat sheet — limited web content available)

## About

Red Hat OpenShift simplifies deployment, management, and scaling of applications, supporting both containers and virtual machines.

In disconnected environments with stringent security requirements, installations require additional consideration, including mirroring of all necessary content locally and steps to simulate an internet connection for OpenShift's functionality.

## Topics covered:

1. Download and configure software on the connected bastion host
2. Transfer the software to the disconnected network
3. Configure the disconnected bastion host
4. Configure the mirror registry on the bastion host
5. Create install-config and agent-config files
6. Generate and load a bootable ISO image for OpenShift
7. Perform post-installation tasks

## Key excerpt (umask/STIG):

Because OpenShift is deployed as a set of containers, a registry is necessary. In disconnected environments, you need to stand up a local registry.

The STIG modifies the user `bashrc` and profile to default to `0077`. During the mirroring process to your local registry, we also build your default catalog source. During that process, we need to ensure that the `umask` is set to `0022` so that OpenShift can read those files within the built container. This is necessary because, by default, OpenShift cannot run containers as root for security reasons.
