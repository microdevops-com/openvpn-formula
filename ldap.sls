{%- if pillar['openvpn']['ldap'] is defined %}
install openvpn-auth-ldap:
  pkg.latest:
    - pkgs:
      - openvpn-auth-ldap

config:
  file.managed:
    - name: {{ pillar['openvpn']['ldap']['path'] }}
    - mode: 600
    - makedirs: True
    - contents: {{ pillar['openvpn']['ldap']['contents'] | yaml_encode }}
{%- endif %}
