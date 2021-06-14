data "ibm_resource_group" "group" {
  name = var.resource_group_name
}
data "ibm_is_image" "image" {
  name = var.instance_image_name
}
data "ibm_is_ssh_key" "ssh_key" {
  name = var.vpc_ssh_key_name
}

locals {
  tags           = []
  resource_group = data.ibm_resource_group.group

  name = var.prefix
  cidr = "10.0.0.0/16"
  zone = "${var.region}-1"
}

resource "ibm_is_vpc" "main" {
  name                      = local.name
  resource_group            = local.resource_group.id
  address_prefix_management = "manual"
  tags                      = local.tags
}
resource "ibm_is_vpc_address_prefix" "main0" {
  name = local.name
  zone = local.zone
  vpc  = ibm_is_vpc.main.id
  cidr = cidrsubnet(local.cidr, 8, 0)
}
resource "ibm_is_subnet" "main0" {
  name            = local.name
  vpc             = ibm_is_vpc.main.id
  zone            = local.zone
  ipv4_cidr_block = ibm_is_vpc_address_prefix.main0.cidr
  resource_group  = local.resource_group.id
}

resource "ibm_is_security_group_rule" "inbound_all" {
  group     = ibm_is_vpc.main.default_security_group
  direction = "inbound"
  remote    = "0.0.0.0/0"
}
resource "ibm_is_security_group_rule" "outbound_all" {
  group     = ibm_is_vpc.main.default_security_group
  direction = "outbound"
  remote    = "0.0.0.0/0"
}
resource "ibm_is_instance" "main0" {
  name           = local.name
  vpc            = ibm_is_vpc.main.id
  resource_group = local.resource_group.id
  zone           = ibm_is_subnet.main0.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  image          = data.ibm_is_image.image.id
  profile        = var.profile

  primary_network_interface {
    subnet = ibm_is_subnet.main0.id
  }
  user_data = <<-EOS
    #!/bin/bash
    set -x
    echo version=1 > /version.txt
    sync;sync
  EOS
}
resource "ibm_is_floating_ip" "main0" {
  resource_group = local.resource_group.id
  name           = local.name
  target         = ibm_is_instance.main0.primary_network_interface[0].id
}
output "resource_group_id" {
  value = local.resource_group.id
}
output "region" {
  value = var.region
}
output "vpc_id" {
  value = ibm_is_vpc.main.id
}
output "zone" {
  value = ibm_is_subnet.main0.zone
}
output "subnet_id" {
  value = ibm_is_subnet.main0.id
}
output "instance_id" {
  value = ibm_is_instance.main0.id
}
output "boot_volume_id" {
  value = ibm_is_instance.main0.volume_attachments[0].volume_id
}
output "floating_ip" {
  value = ibm_is_floating_ip.main0.address
}
output "prefix" {
  value = var.prefix
}
output "profile" {
  value = var.profile
}
output "key_id" {
  value = data.ibm_is_ssh_key.ssh_key.id
}
output "image_id" {
  value = data.ibm_is_image.image.id
}
output "z" {
  value = {
    ssh = "ssh root@${ibm_is_floating_ip.main0.address}"
  }
}
