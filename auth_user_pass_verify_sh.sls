{%- if pillar["openvpn"]["auth_user_pass_verify_sh"] is defined %}

auth_user_pass_verify_sh:
  file.managed:
  - name: {{ pillar["openvpn"]["auth_user_pass_verify_sh"]["script_path"] | default('/etc/openvpn/auth_user_pass_verify.sh') }}
  - mode: 0755
  - user: root
  - contents_pillar: openvpn:auth_user_pass_verify_sh:script_contents

  {%- if pillar["openvpn"]["auth_user_pass_verify_sh"]["install_pkgs"] is defined %}
    {% for pkg in pillar["openvpn"]["auth_user_pass_verify_sh"]["install_pkgs"] %}
install {{ pkg }}:
  pkg.latest:
  - pkgs:
    - {{ pkg }}
    {% endfor %}
  {% endif %}

{% endif %}
