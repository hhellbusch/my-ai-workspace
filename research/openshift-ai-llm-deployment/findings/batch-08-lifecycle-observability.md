# Batch 08 Findings: OpenShift / RHOAI lifecycle and model-serving observability

**Sources analyzed:** ref-56, ref-57, ref-58, ref-59, ref-53  
**Date:** 2026-04-17

_Disclosure: This verification batch was produced with AI assistance._

---

## ref-56: Support lifecycle for Azure Red Hat OpenShift 4 (Microsoft Learn)

**Article claims:** The article cites this source for OpenShift minor release cadence (approximately every four months), Extended Update Support (EUS) on even-numbered minors, EUS Add-on Term 1 as an extra six months of support, and managed-service consequences (for example, loss of SLA if the cluster is not updated before end-of-life, with support becoming “commercially reasonable” for migration).

**Source actually says:** Red Hat ships OCP minor releases about every four months; ARO supports `fast`, `stable`, and `eus` channels only. EUS Add-on Term 1 applies to even-numbered minors starting with 4.16 and is included with the ARO subscription, extending the lifecycle by six months (channel must be switched to `eus-4.y` to receive updates during EUS). Unsupported versions are not covered by the ARO SLA; clusters past end-of-life move to Limited Support, with no runtime or SLA guarantees and “commercially reasonable” assistance to move to a supported version (with possible need for a new cluster if no update path exists). The page includes an ARO-specific release calendar (GA, install availability, stable EOL, EUS Term 1 EOL).

**Verdict:** VERIFIED WITH CAVEATS

**Details:** The Microsoft page substantiates the four-month cadence, even-minor EUS, Term 1 as a six-month extension on ARO, and the managed-service SLA / Limited Support behavior the article describes. It does not define Red Hat’s generic OCP “Full Support vs Maintenance” phase rules (those live in Red Hat policy / ref-57). It also does not support a simplified “~14 months per minor release” summary; calendar examples show longer windows on `stable` for odd minors (for example 4.19 June 2025 to December 2026 in the captured table). Version-specific dates can change; the page footer indicates last update 2025-11-14.

**Impact:** Credibility is strong for ARO-specific lifecycle, channels, and SLA risk, but readers should not treat this page as the full authoritative definition of all OCP lifecycle phases outside ARO.

---

## ref-57: Understanding OpenShift product lifecycles and EUS (Red Hat)

**Article claims:** The article cites this source for structured lifecycle phases: Full Support beginning at GA (minimum six months or 90 days after the next minor’s GA, whichever is later), Maintenance Support ending 18 months after GA, all even-numbered minors designated as EUS releases, and EUS Add-on Term 1 as an additional six months after Maintenance so customers can stay on the same minor for about 24 months.

**Source actually says:** OCP 4 is phased (Full Support, Maintenance Support, EUS). Full Support starts at GA and lasts six months or 90 days after the next minor GA, whichever is later. Maintenance Support runs after Full Support and ends 18 months from that minor’s GA. Even-numbered minors are EUS releases; optional EUS add-ons apply. EUS Term 1 is a six-month optional term after the Maintenance phase for the release, allowing customers to remain on the same minor for a total of 24 months; Term 2 is a further optional 12-month buy-up, extending total support up to 36 months for EUS releases (with subscription / architecture caveats). The resource also states OCP 4 comes with “18 months of full and maintenance support” and lifecycle extensions up to 36 months in the introduction.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** The article’s phase descriptions and the “24 months with EUS Term 1” story align with this Red Hat document. The verification target statement “~14 months per minor release” is not supported here; the documented horizon through end of Maintenance is 18 months from GA, with EUS terms extending beyond that for eligible releases and subscriptions. EUS beyond 24 months requires Term 2 and eligibility rules (Premium vs Standard SLA) that the article does not fully spell out.

**Impact:** Strong backing for the article’s detailed lifecycle subsection when quoted accurately; any standalone “~14 months per minor” shorthand is misleading relative to Red Hat’s published 18-month Maintenance boundary and optional EUS terms.

---

## ref-58: Red Hat OpenShift AI Self-Managed Life Cycle (Red Hat Customer Portal)

**Article claims:** The article cites this source for RHOAI Self-Managed having a release schedule that is independent from OpenShift while versions are mapped to supported OCP ranges (example given: RHOAI 2.25 on OCP 4.16 through 4.20), plus Full/Maintenance/EUS-style channel behavior for the operator.

**Source actually says:** RHOAI Self-Managed is an Operator on OpenShift with a release schedule “independent from other Red Hat products and services”; the OpenShift lifecycle page is referenced for supported OpenShift versions, and supported configurations are pointed to a separate article (including 3.x-specific configs). Upgrade paths follow OLM rules; automatic vs manual upgrade strategy is described. Under “Migrating from 2.x to 3.x”: direct upgrades from OpenShift AI 2.25 or earlier to 3.3 and prior are not supported due to architectural changes; migration from 2.25 to a 3.x version is planned for an upcoming release, with a KB article linked for why 3.0 upgrades were not supported.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** Independence of RHOAI’s schedule versus OCP is explicitly confirmed; explicit “version N requires OCP N−1 or N” wording does not appear in the captured policy text—compatibility is delegated to the supported configurations article. The “no upgrade from 2.x to 3.x” claim is accurate only with nuance: the policy scopes “not supported” to upgrades to 3.3 and earlier from 2.25 or earlier, and explicitly leaves room for a future supported migration path from 2.25. RHOAI 3.x release-channel semantics (GA vs EUS, EA requires fresh install) are more detailed than the article’s summary.

**Impact:** Supports the article’s high-level lifecycle story for Self-Managed and strongly supports a “no direct 2.x→3.x upgrade today” warning, but the article should avoid overstating permanence or universality across all future 3.x minors.

---

## ref-59: Red Hat OpenShift AI Cloud Service Life Cycle (Red Hat Customer Portal)

**Article claims:** The article cites this source for managed hyperscaler-style behavior: the OpenShift AI add-on and components are frequently or automatically updated, and administrators must keep the cluster on a supported version to preserve SLA-style guarantees.

**Source actually says:** The Cloud Service follows a release-driven model with a single supported version at a time. It is an add-on to OpenShift Dedicated and ROSA; its schedule is independent from other products. During GA, supported OpenShift versions listed are 4.18, 4.17, 4.16, and 4.15. The add-on and installed components are automatically updated to the latest version on all clusters. A separate section covers pipelines v2 behavior; end-of-life policy allows discontinuation with one year’s notice and 60-day data retention after service end.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** Automatic updates to the latest add-on version are stated plainly and align with the article’s managed-service narrative. The page gives a fixed list of supported OCP minors for the service period captured; it does not state a general “RHOAI version N supports only OCP N−1 or N” rule. SLA text in this fetch is not as explicit as Microsoft’s ARO SLA language (ref-56); pairing with the relevant managed OpenShift SLA / service definition would be needed for full SLA verification.

**Impact:** Confirms automatic update expectations for the Cloud Service add-on; compatibility claims should cite the supported OCP list or supported-configurations documentation rather than inferring a strict N/N−1 pairing from this page alone.

---

## ref-53: RHOAI Metrics Dashboard for Single Serving Models (ai-on-openshift.io)

**Article claims:** The article cites this source for enabling User Workload Monitoring (User Workload Metrics) to gain a “Single Serving Models” metrics view, with runtimes such as vLLM exposing metrics scraped by Prometheus, supporting tracking of latency, time-to-first-token, token throughput, queue depth, and hardware utilization; the broader article also ties enterprise observability to Grafana and OpenTelemetry for distributed tracing.

**Source actually says:** Enabling RHOAI User Workload Metrics for single-model serving and deploying a Grafana dashboard helps monitor performance and resource usage. Prerequisites include OpenShift 4.10+, RHOAI 2.10+, KServe configured, and (for GPU dashboard panels) NVIDIA GPU Operator. Monitoring configuration is delegated to Red Hat documentation; KServe does not generate its own metrics and relies on runtimes—available metrics depend on the runtime. Optional Service Mesh monitoring is mentioned for mesh traffic. The GPU Operator / DCGM Exporter supplies GPU telemetry to Prometheus viewable in console dashboards. The Grafana overlay provides pre-built dashboards including “vLLM Model Metrics” and “vLLM Service Performance” (and OpenVINO counterparts). OpenTelemetry is not mentioned on this page.

**Verdict:** VERIFIED WITH CAVEATS

**Details:** Prometheus-compatible scraping and Grafana visualization for single-model serving (including vLLM-focused dashboards) are supported by this community guide and align with the article’s Prometheus + Grafana thread for serving metrics. The specific enumerations “latency percentiles” and “cache utilization” are not named in the captured page body; they may appear in linked dashboard definitions or upstream vLLM metrics documentation but are not evidenced here. OpenTelemetry / distributed tracing is not covered by ref-53, so that portion of the article’s observability stack is not verified by this source.

**Impact:** Good corroboration for UWM + Grafana as a practical path for KServe runtime metrics (notably vLLM dashboards), with the caveat that metric cardinality and names are runtime-defined; OpenTelemetry claims require different citations.

---

## Batch Summary

- **Verified:** 0  
- **Verified with caveats:** 5  
- **Problematic:** 0  
- **Unverifiable:** 0  
- **Key pattern in this batch:** Official lifecycle documents (ref-57, ref-58) reward precise wording: “18 months to end of Maintenance,” “24 months on a minor with EUS Term 1,” and “no direct 2.x→3.x upgrade” are all nuanced. Community and vendor pages (ref-53, ref-56) complement Red Hat policy but do not replace supported-configuration matrices for OCP↔RHOAI pairing. The shorthand “~14 months per minor release” is a poor match for ref-57/ref-56 compared to the documented 18-month maintenance boundary (plus optional EUS).
