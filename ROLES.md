# Role docs

```bash
role_name/
├── tasks/           # Основные задачи
│   └── main.yml
├── handlers/        # Обработчики
│   └── main.yml
├── templates/       # Шаблоны Jinja2
│   └── ntp.conf.j2
├── files/           # Статические файлы
│   ├── static.conf
│   └── test.sh
├── vars/            # Переменные связанные с ролью
│   └── main.yml
├── defaults/        # Переменные с низким приоритетом
│   └── main.yml
├── meta/            # Метаданные и зависимости роли
│   └── main.yml
├── library/         # Пользовательские модули
├── module_utils/    # Пользовательские утилиты модулей
└── .../             # И другие типы плагинов ...
```

Meta:
```yaml
galaxy_info:
  author: Your name
  description: A brief description of the role
  company: Your company
  license: MIT
  min_ansible_version: "2.10"
  platforms:
    - name: EL
      versions:
        - 8
    - name: Debian
      versions:
        - bullseye
  galaxy_tags:
    - web
    - security

dependencies:
  - role: common
  - role: geerlingguy.java
    vars:
      java_version: "11"
```

Usage:
```yaml
- hosts: front
  tasks:
    - name: Import front role
      import_role:
        name: front
      vars:
        dir: '/opt/a'
        app_port: 5000

- hosts: front
  roles:
    - common
    - role: front
      vars:
        dir: '/opt/a'
        app_port: 5000
```

```bash
ansible-galaxy role init test --init-path ./roles/
```