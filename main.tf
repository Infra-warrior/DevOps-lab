terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Define a private NAT network for the lab
resource "libvirt_network" "lab_net" {
  name      = "lab_net"
  mode      = "nat"
  domain    = "lab.local"
  addresses = ["10.10.10.0/24"]
}

# 2. Define the Base OS image pool using the file we downloaded
resource "libvirt_volume" "rocky9_base" {
  name   = "rocky9-base.qcow2"
  source = "${abspath(path.module)}/rocky9.qcow2"
  format = "qcow2"
}

# 3. Define the configurations for the two nodes
locals {
  nodes = {
    "ops-node" = { memory = 4096, vcpu = 2 }
    "k8s-node" = { memory = 6144, vcpu = 2 }
  }
}

# 4. Create individual volumes for each node
resource "libvirt_volume" "node_volume" {
  for_each       = local.nodes
  name           = "${each.key}-disk.qcow2"
  base_volume_id = libvirt_volume.rocky9_base.id
  size           = 42949672960 # 40GB disk per VM
}

# 5. Inject Cloud-Init
resource "libvirt_cloudinit_disk" "commoninit" {
  for_each = local.nodes
  name     = "${each.key}-commoninit.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    hostname   = each.key
    public_key = file("~/.ssh/lab_key.pub")
  })
}

# 6. Build the Virtual Machines
resource "libvirt_domain" "lab_nodes" {
  for_each   = local.nodes
  name       = each.key
  memory     = each.value.memory
  vcpu       = each.value.vcpu
  qemu_agent = false

#-- Add This CPU Block ----
  cpu {
	mode = "host-passthrough"
   }

  network_interface {
    network_id     = libvirt_network.lab_net.id
    wait_for_lease = false
  }

  disk {
    volume_id = libvirt_volume.node_volume[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[each.key].id

#Keep the serial console
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
#--- ADD THESE BLOCKS FOR VIRT-MANAGER GUI ---
  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  video {
    type = "qxl"
  }
}

# 7. Output the dynamically assigned IPs
output "node_ips" {
  value = {
    for key, node in libvirt_domain.lab_nodes : key => node.network_interface[0].addresses[0]
  }
}
