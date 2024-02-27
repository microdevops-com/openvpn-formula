# This is the main state file for configuring openvpn.

include:
  - openvpn.repo
  - openvpn.ldap
  - openvpn.install
  - openvpn.adapters
  - openvpn.dhparams
  - openvpn.certificates
  - openvpn.auth_user_pass_verify_sh
  - openvpn.service
  - openvpn.config
  - openvpn.clients_configs
