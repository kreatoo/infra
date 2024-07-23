# kreainfra
Kreato's infrastructure

The goal of this project is to create a simple, reproducible, and secure infrastructure for Kreato services. The configuration includes 2 machines;

# Components

## Machines

* tulip
    * Cloud: OCI (Oracle Cloud Infrastructure)
    * Region: Frankfurt
    * OS: Ubuntu 22.04
    * Kubernetes distro: K3s
    * Role: Kubernetes master node
    * Machine: VM.Standard.A1.Flex (Ampere Altra) with 4 cores, 12GB RAM, 200GB storage
    * Enable using `tulip_create = true` in `creds.tfvars`

* plato
    * Cloud: Hetzner Cloud
    * Region: Helsinki
    * OS: Ubuntu 24.04
    * Kubernetes distro: K3s
    * Role: Kubernetes worker node
    * Machine: CAX11 (Ampere Altra) with 2 cores, 4GB RAM, 40GB storage
    * Enable using `plato_create = true` in `creds.tfvars`

## Networking

* Tailscale
    * tulip
        * Tailscale SSH: Enabled
        * Exit Node: no
        * Tag: tag:k8s-nodes
        * Subnet: 10.42.0.0/16
        * Only gets created if `tulip_create = true` in `creds.tfvars`

    * plato
        * Tailscale SSH: Enabled
        * Exit Node: yes
        * Tag: tag:k8s-nodes
        * Subnet: 10.42.0.0/16
        * Only gets created if `plato_create = true` in `creds.tfvars`

* Cloudflare
    * DNS
        * AAAA
            * plato.kreato.dev
                * proxied: true
                * Only gets created if `plato_create = true` in `creds.tfvars`
        * A
            * tulip.kreato.dev
                * proxied: true
                * Only gets created if `tulip_create = true` in `creds.tfvars`

## Project structure

* dns.tf
    * Cloudflare DNS records

* main.tf
    * plato machine

* oci.tf
    * tulip machine

# Usage
`opentofu` is the only dependency.

Create a `creds.tfvars` file using the template at `creds.tfvars.example`. Fill in the required values. Then run the following commands:

```bash
tofu init
tofu apply --var-file=creds.tfvars
```

# Status
* Hetzner (OK)
* OCI (Mostly OK, needs more testing)
* K3s (OK)
* Tailscale ACL

# License
This project is licensed under AGPLv3.0. See [LICENSE.md](LICENSE.md) for more details.
