packer {
  required_plugins {
    amazon = {
      version = ">= 1.1.6"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

####################
# All variables
####################

variable "skip_create_ami" {
  type      = bool
  sensitive = false
  default   = true
}

####################
# This source will create an EBS AMI from an existing AMI.
#
# * The skip_create_ami option is used to skip the creation of the AMI. This helps debugging the build process.
# * The AMI name is set to a timestamp to ensure uniqueness.
# * The instance type is set to a t3a.medium to build for x86_64.
# * Tags are set to identify the resources created by Packer for easier cleanup.
####################

source "amazon-ebs" "ubuntu" {
  skip_create_ami = var.skip_create_ami
  ami_name        = "docker-{{isotime `2006-01-02-15-04-05`}}"
  instance_type   = "t3a.medium"
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-jammy-22.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"] # Canonical
  }
  ssh_username = "ubuntu"
  run_tags = {
    Creator = "Packer"
  }
  run_volume_tags = {
    Creator = "Packer"
  }
  snapshot_tags = {
    Creator = "Packer"
  }
  tags = {
    Creator = "Packer"
  }
}

####################
# This build will install Docker on the Ubuntu AMI.
# 
# * It's based on the source created above.
# * Wait for cloud-init to finish. This is important to ensure that the instance is
#   fully configured. If this is not done, the instance might not be able to reach the
#   internet or things like apt-get might not work.
# * Upgrade the system to the latest packages.
####################

build {
  name = "docker"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  provisioner "shell" {
    inline = [
      "cloud-init status --wait",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl jq",
      "curl https://releases.rancher.com/install-docker/20.10.sh | sudo bash",
    ]
  }
}

