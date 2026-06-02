# Learning paths

Curated curricula that span multiple areas of this repository (OpenShift, GitOps, labs, troubleshooting). Each path is self-contained under its own folder.

| Path | Audience | Summary |
|------|------------|---------|
| [Git, GitHub, and GitLab](git/README.md) | Anyone learning Git for the first time — developers, writers, researchers, infrastructure engineers | Staged curriculum: inside-out mental model (Schwern), Git vs hosting platforms explained, GitHub Skills, GitLab for Beginners, Microsoft Learn, learngitbranching, Pro Git, enterprise hosting notes. |
| [VMware admins → Kubernetes / OpenShift / OpenShift Virtualization](vmware-admins/README.md) | Platform engineers from a vSphere background | Phased topics, verification checks, Red Hat and third-party links, in-repo labs. Phase 5 introduces ZTP for large fleets; see the dedicated path below for depth. |
| ZTP at scale *(planned)* | Platform engineers operating 50+ clusters at edge or distributed sites | Zero Touch Provisioning deep dive: SiteConfig, PolicyGenTemplate, TALM, ClusterGroupUpgrade, ClusterCurator/AAP, External Secrets Operator. Assumes ACM and completion of the VMware admins path through Phase 4. |

Add new paths as sibling directories (for example `learning-path/<topic>/README.md`) and link them from this index.

*AI-assisted content. See [AI-DISCLOSURE.md](../../AI-DISCLOSURE.md) for review status details.*
