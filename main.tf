terraform {
    required_providers {
        hcloud = {
            source = "hetznercloud/hcloud"
            version = "~> 1.47.0"
        }
        
        cloudflare = {
            source = "cloudflare/cloudflare"
            version = "~> 4.0"
        }

        tailscale = {
            source = "tailscale/tailscale"
            version = "~> 0.16"
        }
    }
}


# Set these using *.tfvars file
# Or using --var="whatever=..." CLI option

variable "plato_create" {
    description = "Create Plato server"
    default = true
}

variable "plato_server_type" {
    description = "Plato server type"
    default = "cax11"
}

variable "tailscale_auth_key" {
    description = "Tailscale Auth Key"
    #sensitive = true
}

variable "k3s_bootstrap_key" {
    description = "K3s bootstrap key from the master node"
    #sensitive = true
}

variable "hetzner_hcloud_token" {
    description = "Hetzner Cloud token"
    sensitive = true
}

provider "hcloud" {
    token = var.hetzner_hcloud_token
}

resource "hcloud_ssh_key" "tofu_key_home" {
    name = "tofu_key_home"
    public_key = file("keys/home_ed25519")
}


#resource "hcloud_ssh_key" "tofu_key_work" {
#    name = "tofu_key_work"
#    public_key = file("keys/work_ed25519")
#}

resource "hcloud_server" "plato" {
    count = var.plato_create ? 1 : 0
    name  = "plato"
    image = "ubuntu-24.04"
    server_type = var.plato_server_type
    ssh_keys = [ "tofu_key_home" ] #, "tofu_key_work"
    public_net {
        ipv4_enabled = true
        ipv6_enabled = true
    }
    
    connection {
        type = "ssh"
        user = "root"
        host = self.ipv4_address
        agent = true
    }
    
    depends_on = [
        oci_core_instance.tulip
    ]
    
    provisioner "remote-exec" {
        inline = [
            "apt-get update -y",
            "apt-get upgrade -y",
            "apt-get install -y wget sudo",
            "wget https://tailscale.com/install.sh -O /tmp/kreato-install.sh",
            "bash /tmp/kreato-install.sh",
            "tailscale up --auth-key=${var.tailscale_auth_key} --advertise-tags=tag:k8s-nodes",
            "wget https://get.k3s.io -O /tmp/kreato-k3s-install.sh",
            "K3S_URL=https://tulip:6443 K3S_TOKEN='${var.k3s_bootstrap_key}' bash /tmp/kreato-k3s-install.sh --vpn-auth='name=tailscale,joinKey=${var.tailscale_auth_key},extraArgs=--ssh'"
        ]
    }
}

resource "hcloud_firewall" "plato_fw" {
    count = var.plato_create ? 1 : 0
    name = "plato_fw"
}

resource "hcloud_firewall_attachment" "plato_fw_attachment" {
    count = var.plato_create ? 1 : 0
    firewall_id = hcloud_firewall.plato_fw.0.id
    server_ids = [hcloud_server.plato.0.id]
}
