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

init-pki:
  cmd.run:
    - name: "./easyrsa init-pki"
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: /opt/EasyRSA/pki

build-ca:
  cmd.run:
    - name: 'echo "Easy-RSA CA" | ./easyrsa build-ca nopass'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: /opt/EasyRSA/pki/ca.crt

gen-req server.req:
  cmd.run:
    - name: 'echo server | ./easyrsa gen-req server nopass'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: /opt/EasyRSA/pki/private/server.key

sing-req server.crt:
  cmd.run:
    - name: 'echo yes | ./easyrsa sign-req server server'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: /opt/EasyRSA/pki/issued/server.crt

HMAC ta.key generation:
  cmd.run:
    - name: 'openvpn --genkey --secret ta.key'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: /opt/EasyRSA/ta.key

crl.pem init generation:
  cmd.run:
    - name: './easyrsa gen-crl; cp /opt/EasyRSA/pki/crl.pem /etc/openvpn/server/crl.pem'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates:
      - /etc/openvpn/server/crl.pem
      - /opt/EasyRSA/pki/crl.pem

{%- for client in pillar["openvpn"]["server_clients"] %}
  {%- if 'delete' in client and client['delete'] %}
revoke {{ client['name'] }} certificate:
  cmd.run:
    - name: 'echo yes | ./easyrsa revoke {{ client['name'] }}'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - onlyif:
      - fun: file.file_exists
        path: {{ '/opt/EasyRSA/pki/private/' + client['name'] + '.key' }}
    - onchanges_in:
      - cmd: "gen-crl after cert changes"

  {% else %}
gen-req {{ client['name'] }}.req:
  cmd.run:
    - name: echo {{ client['name'] }} | ./easyrsa gen-req {{ client['name'] }} nopass
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: {{ '/opt/EasyRSA/pki/private/' + client['name'] + '.key' }}
    - onchanges_in:
      - cmd: "gen-crl after cert changes"

sing-req {{ client['name'] }}.crt:
  cmd.run:
    - name: echo yes | ./easyrsa sign-req client {{ client['name'] }}
    - cwd: /opt/EasyRSA
    - shell: /bin/bash
    - creates: {{ '/opt/EasyRSA/pki/issued/' + client['name'] + '.crt' }}
    - onchanges_in:
      - cmd: "gen-crl after cert changes"
  {%- endif %}
{%- endfor %}

gen-crl after cert changes:
  cmd.run:
    - name: './easyrsa gen-crl; cp /opt/EasyRSA/pki/crl.pem /etc/openvpn/server/crl.pem'
    - cwd: /opt/EasyRSA
    - shell: /bin/bash

{%- for server_name, server_params in pillar["openvpn"]["server"].items() %}
restart {{ server_name }} server after revoking:
  cmd.run:
    - name: systemctl restart openvpn-server@{{ server_name }}
    - onchanges:
      - cmd: "gen-crl after cert changes"
{%- endfor %}
