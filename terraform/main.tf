resource "virtualbox_vm" "ubuntu" {
  provider = vbox

  name          = var.vm_name
  image         = "${path.module}/images/ubuntu-jammy-amd64.box"
  optical_disks = ["${path.module}/cloud-init-seed.iso"]
  cpus          = var.cpu
  memory        = format("%.1fgib", var.memory_mb / 1024)

  boot_order = ["disk", "none", "none", "none"]

  os_type = "Ubuntu22_LTS_64"
  status  = "running"
  gui     = false

  graphics_controller = "vboxsvga"
  clipboard_mode      = "bidirectional"
  drag_and_drop       = "bidirectional"

  user_data = templatefile("${path.module}/cloud-init.yaml", {
    hostname       = var.vm_name
    username       = var.cloud_init_user
    ssh_public_key = trimspace(file(pathexpand(var.ssh_public_key_path)))
  })

  lifecycle {
    ignore_changes = [
      network_adapter[0].device,
    ]
  }

  network_adapter {
    type   = var.network
    device = "IntelPro1000MTDesktop"
  }
}
