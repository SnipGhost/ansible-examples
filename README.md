# Examples

```bash
terraform init
terraform apply
terraform output -raw private_key > ~/.ssh/id_rsa_tmp
chmod 400 ~/.ssh/id_rsa_tmp

ansible-inventory -i inventory/hosts.yml --list
ansible-inventory -i inventory/ --list
ansible-inventory --list  
ansible front -m raw -a "uname -a"

ansible-playbook playbook.yaml -l front
```