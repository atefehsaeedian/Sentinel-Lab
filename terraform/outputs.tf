output "vm_name" {
  description = "Name of the created VirtualBox VM"
  value       = virtualbox_vm.ubuntu.name
}

output "ssh_command" {
  description = "Command to connect to the VM from the Mac"
  value       = "ssh -p ${var.ssh_host_port} ${var.cloud_init_user}@127.0.0.1"
}
