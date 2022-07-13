create configs dir:
  file.directory:
    - name: /etc/openvpn/client-configs/
    - makedirs: True

{%- for client in pillar['openvpn']['server_clients'] %}
{%-   if 'delete' in client and client['delete'] %}
remove {{ client['name'] }} config:
  file.absent:
    - name: /etc/openvpn/client-configs/{{ client['name'] }}.ovpn
{%    else %}
create config {{ client['name'] }}:
  file.managed:
    - name: /etc/openvpn/client-configs/{{ client['name'] }}.ovpn
    - source: 
        - salt://openvpn/files/clients_base_config.j2
    - template: jinja
    - defaults: 
        client: {{ client }}
{%-   endif %}
{%- endfor %}
