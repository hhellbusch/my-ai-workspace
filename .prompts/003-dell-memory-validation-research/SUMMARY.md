# Dell Memory Validation Detection Research

**Dell PowerEdge memory validation failures are definitively detectable via iDRAC Redfish API and System Event Logs, enabling post-facto auditing of production servers without reboot or OS dependencies.**

## Version
v1 - Initial research completed 2025-12-17

## Key Findings

• **Primary Method**: iDRAC Redfish API (`/redfish/v1/Systems/System.Embedded.1/Memory`) provides authoritative hardware inventory with explicit health status per DIMM slot - this is the gold standard for detection

• **Historical Evidence**: System Event Log (SEL) via Redfish API contains definitive records of POST memory failures with specific slot identification, timestamps, and error descriptions

• **Cross-Reference Detection**: Comparing iDRAC-reported installed capacity with OS-detected memory (`/proc/meminfo`) quantifies failed memory through discrepancy calculation

• **CoreOS Compatibility**: Out-of-band Redfish approach is ideal for immutable CoreOS - requires no tools on nodes, works independently of OS state

• **Fleet Automation**: Ansible `community.general.redfish_info` module enables scalable auditing of hundreds of servers with automated report generation

• **OpenShift Integration**: Use `oc` commands for initial screening to identify outlier nodes, then perform detailed iDRAC investigation on suspects

• **Limitation**: In-band Linux methods (dmidecode, kernel logs) show only validated memory - failed modules simply don't appear rather than showing error status, making them indirect detection requiring external reference

## Recommendations

• **HIGH PRIORITY**: Implement iDRAC Redfish API queries as primary detection method - provides out-of-band, authoritative hardware inventory

• **HIGH PRIORITY**: Check SEL logs for historical POST failure evidence - this provides the "smoking gun" for servers already in production

• **HIGH PRIORITY**: Create Ansible playbook combining Redfish memory inventory, SEL checks, and OS memory comparison for fleet-wide systematic audit

• **MEDIUM PRIORITY**: Use OpenShift `oc describe node` for initial screening to identify nodes with unexpected capacity before detailed investigation

• **PREVENTIVE**: Enable BIOS "System Memory Testing" setting for future deployments to ensure thorough POST validation

## Decisions Needed

• **Automation approach**: Shell scripts vs. Ansible vs. Python - depends on existing infrastructure and scale (Ansible recommended for 100+ servers)

• **Audit schedule**: One-time audit vs. ongoing monitoring - recommend initial comprehensive audit followed by periodic checks

• **Remediation strategy**: Will servers with failed memory be repaired immediately or scheduled for maintenance window?

• **Threshold calibration**: Confirm system reserved memory amounts on sample servers to set accurate discrepancy detection thresholds (currently using ~2-4GB estimate)

## Blockers

• **iDRAC access**: Need iDRAC IP addresses, credentials, and network access for all servers in scope (verify iDRAC Enterprise license level for full API access)

• **Expected capacity data**: Need to know expected memory configuration per server (from purchase order/inventory) to identify discrepancies

• **Tool availability**: Need curl, jq, and optionally Ansible installed on system running audits

• **Hands-on verification needed**: iDRAC firmware version, SEL retention settings, and actual system reserved memory amounts should be verified on sample systems before large-scale deployment

## Next Step

**Create Ansible playbook to audit all affected servers**: Combine Redfish API memory inventory queries, SEL log checks, and OS memory comparison to generate comprehensive report identifying all servers where memory failed POST validation. Start with sample/test playbook on 3-5 servers to validate methodology, then scale to full fleet. Expected timeline: 2-4 hours for playbook development, 1-2 hours for fleet-wide execution and report generation.

Alternative if Ansible not available: Implement shell script version (see code examples in research) and execute via loop over server list.


