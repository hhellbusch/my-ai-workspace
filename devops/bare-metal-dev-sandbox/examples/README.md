# Live preflight — copy, edit placeholders, do not commit secrets.
#
#   cp examples/live-preflight-vars.example.json ~/live-preflight.json
#   export BMC_USERNAME=root BMC_PASSWORD=...
#   # optional when probe_from is not local:
#   cp examples/live-inventory.example.ini ~/live-inventory.ini
#   INVENTORY=~/live-inventory.ini ./scripts/run-live.sh ~/live-preflight.json
#
# Credentials: export BMC_USERNAME / BMC_PASSWORD (or BMC_USER). merge-live-vars.py
# injects them into extra-vars — leave credentials {} in the JSON file.
#
# probe_from:
#   local | localhost  — TCP probes run from the Ansible controller
#   bastion            — delegate wait_for to inventory host (see live-inventory.example.ini)
#
# Hub version: read via oc on the machine running the playbook (kubeconfig must point at hub).
