variable "cloudflare_api_token" {
    description = "CloudFlare API token"
    sensitive = true
}

variable "cloudflare_zone_id" {
    description = "Zone ID"
    sensitive = true
}

provider "cloudflare" {
    api_token = var.cloudflare_api_token
}

resource "cloudflare_record" "tulip" {
    count = var.tulip_create ? 1 : 0
    zone_id = var.cloudflare_zone_id
    name = "tulip"
    value = oci_core_instance.tulip[*].public_ip
    type = "A"
    proxied = true
}

resource "cloudflare_record" "plato" {
    count = var.plato_create ? 1 : 0
    zone_id = var.cloudflare_zone_id
    name = "plato"
    value = hcloud_server.plato.0.ipv6_address
    type = "AAAA"
    proxied = true
}

