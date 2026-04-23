data "vkcs_compute_flavor" "default" {
  name = var.compute_flavor
}

data "vkcs_images_image" "ubuntu" {
  visibility = "public"
  default    = true
  properties = {
    mcs_os_distro  = "ubuntu"
    mcs_os_version = "24.04"
  }
}

resource "vkcs_networking_secgroup" "secgroup_http" {
  name        = "www"
  description = "security group for http 80"
}

resource "vkcs_networking_secgroup_rule" "secgroup_http" {
  direction         = "ingress"
  port_range_max    = 80
  port_range_min    = 80
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.secgroup_http.id
}

data "vkcs_networking_secgroup" "ssh" {
  name = "ssh"
}

data "vkcs_networking_secgroup" "default" {
  name = "default"
}

resource "vkcs_compute_keypair" "default_key_pair" {
  name = "default_key_test"
}

resource "vkcs_compute_instance" "compute" {
  count     = 1
  name      = "test-vm-${count.index + 1}"
  flavor_id = data.vkcs_compute_flavor.default.id
  key_pair  = vkcs_compute_keypair.default_key_pair.name
  # config-drive нужен только для ВМ с портами во внешней сети
  config_drive = "true"
  security_group_ids = [
    data.vkcs_networking_secgroup.default.id,
    data.vkcs_networking_secgroup.ssh.id,
    vkcs_networking_secgroup.secgroup_http.id
  ]
  availability_zone = var.availability_zone_name
  block_device {
    uuid                  = data.vkcs_images_image.ubuntu.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 10
    boot_index            = 0
    delete_on_termination = true
  }
  network {
    name = "internet"
  }

  user_data = templatefile("${path.module}/user-data.yaml.tftpl", {
    ansible_public_key = vkcs_compute_keypair.default_key_pair.public_key
  })
}

output "instance_ip" {
  value = [for i in vkcs_compute_instance.compute : i.access_ip_v4]
}

# To list value use: terraform output -raw private_key
output "private_key" {
  value     = vkcs_compute_keypair.default_key_pair.private_key
  sensitive = true
}
