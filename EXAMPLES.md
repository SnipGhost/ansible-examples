# Features


## Docs

```bash
ansible-doc -F
ansible-doc package
ansible-doc -s package
```


## Inventory

```bash
ansible-playbook -i "192.168.8.136," test.yml
ansible-playbook -i "host1.local,host2.local" test.yml

ansible-inventory --graph
ansible --list-host back
```


## check_mode + diff
```bash
ansible-playbook -l back playbook.yaml --diff --check
ansible-playbook -l back playbook.yaml -D -C
```


## Limit
```bash
# per hosts
ansible-playbook test.yml -l front1
ansible-playbook test.yml -l "front1,front2"
# per group/s
ansible-playbook test.yml -l front
ansible-playbook test.yml -l back
ansible-playbook test.yml -l "front,back"
# hosts in group front AND in group back
ansible-playbook test.yml -l "front:&back"
# hosts in group front AND NOT in group back
ansible-playbook test.yml -l 'font:!back'

ansible-playbook playbook.yaml --limit "front:&back"
ansible-playbook playbook.yaml --limit 'db[0:2]'
```


## Start at task

```bash
ansible-playbook playbook.yaml --list-tasks

ansible-playbook playbook.yaml --start-at-task "Install additional packages"
```


## Debug

```bash
ansible-playbook -l back playbook.yaml --step -vvv
```


## Tags

```yaml
- name: Install additional packages
  apt:
    name: nano
    state: present
  tags: [packages]
```

```bash
ansible-playbook -l back playbook.yaml --tags packages
ansible-playbook -l back playbook.yaml --skip-tags packages
```

Кроме того, зарезервированные [теги](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_tags.html):
- all
- always
- never
- tagged
- untagged

```bash
ansible-playbook playbook.yaml --list-tags
ansible-playbook playbook.yaml --tags "test,packages" --list-tasks
```


## Serial + throttle

```yaml
- hosts: web
  serial: 20%
  tasks:
    - service: name=myapp state=restarted
```
Можно комбинировать с `throttle`


## Strategy

[Documentation](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_strategies.html)

```yaml
- hosts: all
  strategy: free
```


## Block + Try-Catch

```yaml
- block:
    - command: /usr/local/bin/do_something
  rescue:
    - debug: msg="Failed, running rollback"
  always:
    - debug: msg="Always done"
```


## Handlers

```yaml
- template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: reload nginx

handlers:
  - name: reload nginx
    service:
      name: nginx
      state: reloaded
```

```yaml
handlers:
  - name: restart apache
    service: name=httpd state=restarted
    listen: "web server changed"

  - name: verify service
    command: /usr/bin/check_http_status
    listen: "web server changed"

tasks:
  - name: update configuration
    template: src=site.conf.j2 dest=/etc/httpd/conf.d/site.conf
    notify: "web server changed"
```

```yaml
- meta: flush_handlers
```
+ Кроме того meta полезен и для [других задач](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/meta_module.html)


## Register
## When

```yaml
- name: Start consul service
  systemd:
    name: consul
    state: started
    daemon_reload: yes
    enabled: yes
    no_block: "{{ consul_server }}"
  register: consul_started

handlers:
  - name: restart consul server
    systemd:
      name: consul
      state: restarted
      daemon_reload: yes
      enabled: yes
    register: consul_restarted
    when: not consul_started.changed

  - name: reload consul server
    systemd:
      name: consul
      state: reloaded
    when: 
      - not consul_started.changed
      - not (consul_restarted.changed | default(false))
```


## command / shell / raw

| Module    | Executes Via            | Shell Features | Requires Python |
|-----------|-------------------------|----------------|-----------------|
| command   | Directly (OS call)      | No             | Yes             |
| shell     | /bin/sh (remote shell)  | Yes            | Yes             |
| raw       | SSH (native)            | Yes            | No              |

```yaml
- name: Check testfile
  shell: test -f /tmp/testfile.txt && echo "File exists"
  register: result
  changed_when: false

- name: Output result of check
  debug:
    msg: "{{ result.stdout }}"
```


## Контроль идемпотентности

```yaml
- command: /usr/bin/python3 /root/status.py
  register: out
  changed_when: "'needs_update' in out.stdout"
  failed_when: out.rc not in [0, 2]
```


## check_mode
## until + retries + delay
## run_once
## delegate_to
## become + become_user

```yaml
- name: Download prometheus node_exporter to local folder
  become: false
  get_url:
    url: "{{ node_exporter_download_link }}"
    dest: "/tmp/{{ node_exporter_pack_name }}.{{ node_exporter_pack_ext }}"
  register: _download_archive
  until: _download_archive is succeeded
  retries: 3
  delay: 2
  run_once: true
  delegate_to: localhost
  check_mode: false
```


## include / import + loop

```yaml
- include: 
- import_tasks: "install-Debian.yml"
- include_tasks: "install-{{ ansible_facts.os_family }}.yml"

# Copied to every task
- import_tasks: "test.yml"
  when: ansible_facts.os_family == "Debian"

# Computed once
- include_tasks: "test.yml"
  when: ansible_facts.os_family == "Debian"

- include_tasks: "install_package.yaml"
  loop: "{{ packages | flatten(1) }}"
  loop_control:
    loop_var: package_name # Reference as {{ package_name }} (default: item)
    label: "{{ package_name.name }}"

## handlers in include cannot notified by name outside include!
```

```yaml
- name: Generate haproxy systemd unit
  template:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    mode: "{{ item.mode }}"
    owner: root
    group: root
    backup: yes
  with_items:
    - { src: haproxy.service.j2, dest: /lib/systemd/system/haproxy.service, mode: '0644' }
    # - [one, two]
    # - three
  notify: restart haproxy
```


## Silence

```yaml
- name: Login
  become: yes
  shell: echo "{{ your_password }}" | passwd --stdin "{{ yout_user }}"
  no_log: true
```


## Assertions

```yaml
- assert:
    that:
      - ansible_facts.memtotal_mb >= 2048
      - my_var is defined
    fail_msg: "Host {{ inventory_hostname }} does not fit requirements"
```


## Pre/Post tasks

```yaml
- hosts: app
  pre_tasks:
    - assert:
        that:
          - ansible_facts.os_family == "Debian"
          - ansible_facts.distribution_major_version | int >= 22
  roles:
    - common
    - app
  post_tasks:
    - debug: msg="Deploy completed"
    - name: Send notification to Telegram
      community.general.telegram:
        token: "{{ tg_bot_token }}"
        api_args:
          chat_id: "{{ tg_chat_id }}"
          text: "Deployment completed!"
          parse_mode: "markdown"
```


# Zero-error tolerance

```yaml
- hosts: db
  any_errors_fatal: true
  max_fail_percentage: 0
  ...
```
