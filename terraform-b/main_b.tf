data "terraform_remote_state" "terraform_a" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform-a/terraform.tfstate"
  }
}

locals {
  prefix            = data.terraform_remote_state.terraform_a.outputs.prefix
  name              = "${local.prefix}-b"
  image_name        = var.image_name
  region            = data.terraform_remote_state.terraform_a.outputs.region
  vpc_id            = data.terraform_remote_state.terraform_a.outputs.vpc_id
  resource_group_id = data.terraform_remote_state.terraform_a.outputs.resource_group_id
  zone              = data.terraform_remote_state.terraform_a.outputs.zone
  key_id            = data.terraform_remote_state.terraform_a.outputs.key_id
  image_id          = data.terraform_remote_state.terraform_a.outputs.image_id
  profile           = data.terraform_remote_state.terraform_a.outputs.profile
  subnet_id         = data.terraform_remote_state.terraform_a.outputs.subnet_id
}

data "ibm_is_image" "image_b" {
  name = local.image_name
}

resource "ibm_is_instance" "mainb" {
  name           = local.name
  vpc            = local.vpc_id
  resource_group = local.resource_group_id
  zone           = local.zone
  keys           = [local.key_id]
  image          = data.ibm_is_image.image_b.id
  profile        = local.profile

  primary_network_interface {
    subnet = local.subnet_id
  }
}

resource "ibm_is_floating_ip" "mainb" {
  resource_group = local.resource_group_id
  name           = local.name
  target         = ibm_is_instance.mainb.primary_network_interface[0].id
}

output "floating_ip" {
  value = ibm_is_floating_ip.mainb.address
}
output "z" {
  value = {
    ssh = "ssh root@${ibm_is_floating_ip.mainb.address}"
  }
}
