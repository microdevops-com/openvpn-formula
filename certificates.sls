easyrsa install:
  archive.extracted:
    - name: /opt/EasyRSA
    - source: {{ pillar['openvpn']['easyrsa']['tgz_link'] }}
    - skip_verify: True
    - enforce_toplevel: False
    - options: --strip-components=1

vars creating:
  file.managed:
    - name: '/opt/EasyRSA/vars'
    - contents_pillar: openvpn:easyrsa:vars

{%- if not salt['file.directory_exists']('/opt/EasyRSA/pki') %}
init-pki:
  cmd.run:
    - name: "./easyrsa init-pki"
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{% else %}
init-pki ready:
  cmd.run:
    - name: echo "EasyRSA PKI infrastucture already initialized"
{%- endif %}
{%- if not salt['file.file_exists']('/opt/EasyRSA/pki/ca.crt') %}
build-ca:
  cmd.run:
    - name: 'echo "Easy-RSA CA" | ./easyrsa build-ca nopass'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{% else %}
build-ca ready:
  cmd.run:
    - name: echo "CA already built"
{%- endif %}
{%- if not salt['file.file_exists']('/opt/EasyRSA/pki/private/server.key') %}
gen-req server.req:
  cmd.run:
    - name: 'echo server | ./easyrsa gen-req server nopass'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{% else %}
gen-req server.req ready:
  cmd.run:
    - name: echo "server.req and server.key already created"
{%- endif %}
{%- if not salt['file.file_exists']('/opt/EasyRSA/pki/issued/server.crt') %}
sing-req server.crt:
  cmd.run:
    - name: 'echo yes | ./easyrsa sign-req server server'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{% else %}
sign-req server.crt ready:
  cmd.run:
    - name: echo "server.crt already issued"
{%- endif %}

{%- if not salt['file.file_exists']('/opt/EasyRSA/ta.key') %}
HMAC ta.key generation:
  cmd.run:
    - name: 'openvpn --genkey --secret ta.key'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{% else %}
HMAC ta.key generation ready:
  cmd.run:
    - name: echo "ta.key already genered"
{%- endif %}
{%- if not salt['file.file_exists']('/opt/EasyRSA/pki/crl.pem') %}
crl.pem init generation:
  cmd.run:
    - name: './easyrsa gen-crl; cp /opt/EasyRSA/pki/crl.pem /etc/openvpn/server/crl.pem'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{% else %}
crl.pem generation ready:
  cmd.run:
    - name: echo "crl.pem already genered"
{%- endif %}

{% set flag = salt["cmd.shell"]('date +%s%N') %}
remove flag before:
  file.absent:
    - name: /tmp/{{ flag }}
{%- for client in pillar["openvpn"]["server_clients"] %}
{%-   if 'delete' in client and client['delete'] %}
{%-     if salt['file.file_exists']('/opt/EasyRSA/pki/private/' + client['name'] + '.key') %}
create_flag:
  file.touch:
    - name: /tmp/{{ flag }}
revoke {{ client['name'] }} certificate:
  cmd.run:
    - name: 'echo yes | ./easyrsa revoke {{ client['name'] }}'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{%      endif %}
{%    else %}
{%-     if not salt['file.file_exists']('/opt/EasyRSA/pki/private/' + client['name'] + '.key') %}
gen-req {{ client['name'] }}.req:
  cmd.run:
    - name: echo {{ client['name'] }} | ./easyrsa gen-req {{ client['name'] }} nopass
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{%-     else %}
gen-req {{ client['name'] }}.req ready:
  cmd.run:
    - name: echo "{{ client['name'] }}.req and {{ client['name'] }}.key already created"
{%-     endif %}
{%-     if not salt['file.file_exists']('/opt/EasyRSA/pki/issued/' + client['name'] + '.crt') %}
sing-req {{ client['name'] }}.crt:
  cmd.run:
    - name: echo yes | ./easyrsa sign-req client {{ client['name'] }}
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
{%-     else %}
sign-req {{ client['name'] }}.crt ready:
  cmd.run:
    - name: echo "{{ client['name'] }}.crt already issued"
{%-     endif %}    
{%-   endif %}
{%- endfor %}
gen-crl arter cert revocation:
  cmd.run:
    - name: './easyrsa gen-crl; cp /opt/EasyRSA/pki/crl.pem /etc/openvpn/server/crl.pem'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - onlyif:
        - fun: file.file_exists
          path: /tmp/{{ flag }}
{%- for server_name, server_params in pillar["openvpn"]["server"].items() %}
restart {{ server_name }} server after revoking:
  cmd.run:
    - name: systemctl restart openvpn-server@{{ server_name }}
    - onlyif:
        - fun: file.file_exists
          path: /tmp/{{ flag }}
{%- endfor %}
remove flag after:
  file.absent:
    - name: /tmp/{{ flag }}
