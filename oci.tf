variable "tulip_create" {
    description = "Create the tulip instance. Please note that creating tulip is not well-tested and may not work as expected."
    type = bool
    default = true
}

variable "tulip_vcpus" {
    description = "Number of vCPUs for the tulip instance"
    type = number
    default = 1
}

variable "tulip_memory" {
    description = "Amount of memory in GB for the tulip instance"
    type = number
    default = 2
}

variable "tulip_storage" {
    description = "Amount of storage in GB for the tulip instance"
    type = number
    default = 50
}

variable "tulip_shape" {
    description = "Shape of the tulip instance"
    type = string
    default = "VM.Standard.A1.Flex"
}

variable "oci_instance_availability_domain" {
    sensitive = true
}

variable "oci_compartment_id" {
    sensitive = true
}

variable "oci_tenancy_ocid" {
    description = "OCID for the tenancy"
    sensitive = true
}

variable "oci_user_ocid" {
    description = "OCID for the user"
    sensitive = true
}

variable "oci_fingerprint" {
    sensitive = true
}

variable "oci_private_key_path" {
    sensitive = true
}

variable "oci_region" {
    description = "Region of account"
    sensitive = true
}

provider "oci" {
    tenancy_ocid = var.oci_tenancy_ocid
    user_ocid            = var.oci_user_ocid
    fingerprint            = var.oci_fingerprint
    private_key_path = var.oci_private_key_path
    region                  = var.oci_region
}

data "oci_core_images" "tulip" {
    count = var.tulip_create ? 1 : 0
    compartment_id = var.oci_compartment_id
    
    operating_system = "Canonical Ubuntu"
    operating_system_version = "22.04"
    
    #filter {
        #name = "display_name"
        #values = ["^.*-aarch64-.*$"]
        #regex = true
    #}

    shape = var.tulip_shape
}

resource "oci_core_vcn" "tulip" {
    count = var.tulip_create ? 1 : 0
    compartment_id = var.oci_compartment_id
    cidr_blocks = ["10.0.0.0/16"]
}

resource "oci_core_subnet" "tulip" {
    count = var.tulip_create ? 1 : 0
    cidr_block = "10.0.1.0/24"
    compartment_id = var.oci_compartment_id
    vcn_id = oci_core_vcn.tulip[*].id
    display_name = "tulip-subnet"
}

resource "oci_core_instance" "tulip" {
    count = var.tulip_create ? 1 : 0

    compartment_id = var.oci_compartment_id
    shape = var.tulip_shape

    availability_domain = var.oci_instance_availability_domain
    display_name = "tulip"
   
    shape_config {
        ocpus = var.tulip_vcpus
        memory_in_gbs = var.tulip_memory
    }

    create_vnic_details {
        assign_ipv6ip = true
        assign_public_ip = true
        subnet_id = oci_core_subnet.tulip[*].id 
    }    
    
    source_details {
        source_id = data.oci_core_images.tulip[*].images.0.id
        source_type = "image"
        boot_volume_size_in_gbs = var.tulip_storage
    }

    metadata = {
        ssh_authorized_keys = file("keys/home_ed25519")
    }

    provisioner "remote-exec" {
        inline = [
            "apt-get update -y",
            "apt-get upgrade -y",
            "apt-get install -y wget sudo",
            "wget https://tailscale.com/install.sh -O /tmp/kreato-install.sh",
            "bash /tmp/kreato-install.sh",
            "tailscale up --auth-key=${var.tailscale_auth_key} --advertise-tags=tag:k8s-nodes",
            "wget https://get.k3s.io -O /tmp/kreato-k3s-install.sh",
            "bash /tmp/kreato-k3s-install.sh --vpn-auth='name=tailscale,joinKey=${var.tailscale_auth_key},extraArgs=--ssh'"
        ]
    }

}
