{%- set client_config_dir = "/etc/openvpn/server/perclient" %}

create configs dir:
  file.directory:
    - name: /etc/openvpn/client-configs/
    - makedirs: True

{%- for client in salt["pillar.get"]("openvpn:server_clients", {}) %}
  {%- set client_name = client["name"] %}

  {%- if "delete" in client and client["delete"] %}
remove {{ client_name }} config:
  file.absent:
    - name: /etc/openvpn/client-configs/{{ client["name"] }}@{{ pillar["openvpn"]["clients_base_config"]["remote"] }}.ovpn

  {% else %}
create config {{ client_name }}:
  file.managed:
    - name: /etc/openvpn/client-configs/{{ client["name"] }}@{{ pillar["openvpn"]["clients_base_config"]["remote"] }}.ovpn
    - source: 
        - salt://openvpn/files/clients_base_config.j2
    - template: jinja
    - defaults: 
        client: {{ client }}

    {% if "config" in client %}
openvpn_config_{{ client_name }}_client_config:
  file.managed:
    - name: {{ client_config_dir }}/{{ client_name }}
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
    - contents: {{ client["config"] | tojson }}
    {% endif %}

  {%- endif %}
{%- endfor %}
