# Source Manifest

**Subject:** iDRAC credential management and HashiCorp Vault (landscape survey)
**URL:** (topic research — no single seed article)
**Analysis started:** 2026-09-26
**Total references:** 14
**Fetched:** 14 of 14 on disk (2 partial — InfoHub reCAPTCHA)

**Organizing question:** How do you run OpenShift / BMC lifecycle with short-lived or Vault-rotated iDRAC service accounts, with HashiCorp Vault as system of record (OME/SCG/DTIAS as contrast)?
**Analysis status:** Batches 01–03 written 2026-09-26 — synthesis pending

---

| ref_id | url | status | file | notes |
| --- | --- | --- | --- | --- |
| ref-01 | https://infohub.delltechnologies.com/en-us/p/announcing-idrac-credential-management-in-openmanage-enterprise-4-0/ | fetched | sources/ref-01.txt | Partial: InfoHub reCAPTCHA; search-snippet reconstruction. OME 4.0 = internal rotation + CyberArk (not Vault) |
| ref-02 | https://www.dell.com/support/kbdoc/en-us/000219279/openmanage-enterprise-4-0-idrac-password-management-and-rotation | fetched | sources/ref-02.txt | Dell KB: OME iDRAC password management, licenses, CyberArk setup |
| ref-03 | https://www.dell.com/support/manuals/en-us/dell-openmanage-enterprise/ome_4_3_online_help_and_user_guide/internal-idrac-credential-management?guid=guid-fdc1198c-f73e-4318-a77e-914d7436b96a&lang=en-us | fetched | sources/ref-03.txt | Via WebFetch (scraper 403). OME internal service account behavior |
| ref-04 | https://www.dell.com/support/manuals/en-us/dell-openmanage-enterprise/ome_4_5_online_help_user_guide/enable-cyberark-integration-for-password-management?guid=guid-ca8bf0fb-a4b2-4785-84a4-7c7761176fdf&lang=en-us | fetched | sources/ref-04.txt | Via WebFetch. OME CyberArk only; not supported on iDRAC 10 / 17G |
| ref-05 | https://www.dell.com/support/manuals/en-us/secure-connect-gateway-app-edition/scg_5.x_app_ug/credential-vault?guid=guid-8b109e79-698f-459e-895f-8f5587d252cd&lang=en-us | fetched | sources/ref-05.txt | Via WebFetch. SCG vault types include HashiCorp Vault |
| ref-06 | https://www.dell.com/support/manuals/en-us/secure-connect-gateway/scg_5.x_ve_ug/add-account-credentials?guid=guid-2093fc52-86fe-435e-94d2-97e05cd6d47a&lang=en-us | fetched | sources/ref-06.txt | Via WebFetch. HashiCorp: secret path + username/password identifiers; example `SCGSecrets/iDRAC` |
| ref-07 | https://www.dell.com/support/manuals/en-us/secure-connect-gateway-ve/scg_rest_api_guide/create-a-credential-vault?guid=guid-5c42ecd5-e867-4a60-ad7b-1aa49b9d1ea5&lang=en-us | fetched | sources/ref-07.txt | Via WebFetch. REST create with `VAULTTYPE=HASHICORPVAULT` |
| ref-08 | https://www.dell.com/support/manuals/en-us/secure-connect-gateway-ve/scg_rest_api_guide/credential-vault?guid=guid-34d72649-a94c-4201-9d4f-1763604266d9&lang=en-us | fetched | sources/ref-08.txt | Via WebFetch. HashiCorp: CLIENTLOGINNAME=Path, ORGACCOUNTNAME=Namespace |
| ref-09 | https://infohub.delltechnologies.com/en-us/l/dell-telecom-infrastructure-automation-suite-2-5-installation-and-administration-guide/integrating-hashicorp-vault-10/ | fetched | sources/ref-09.txt | Partial: InfoHub reCAPTCHA; search-snippet reconstruction. DTIAS BMC secrets in Vault Enterprise |
| ref-10 | https://docs.ansible.com/projects/ansible/latest/collections/community/hashi_vault/hashi_vault_lookup.html | fetched | sources/ref-10.txt | Ansible Vault lookup for automation consumers |
| ref-11 | https://docs.ansible.com/projects/ansible/latest/collections/community/general/idrac_redfish_command_module.html | fetched | sources/ref-11.txt | Ansible iDRAC Redfish OEM: username/password/auth_token |
| ref-12 | https://book.metal3.io/bmo/introduction | fetched | sources/ref-12.txt | Metal³ BMH: BMC credentials as K8s Secret (`credentialsName`) |
| ref-13 | https://external-secrets.io/latest/provider/hashicorp-vault/ | fetched | sources/ref-13.txt | ESO Vault provider: pull/push into cluster |
| ref-14 | https://github.com/cobaltcore-dev/metal-credential-sync | fetched | sources/ref-14.txt | Operator syncing BMC secrets → Vault/OpenBao |
