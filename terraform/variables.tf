variable "vm_name" {
  description = "Name of the Terraform-managed Ubuntu VM"
  type        = string
  default     = "tf-ubuntu-lab"
}

variable "cpu" {
  description = "Number of virtual CPUs"
  type        = number
  default     = 2

  validation {
    condition     = var.cpu >= 1 && var.cpu <= 4
    error_message = "CPU must be between 1 and 4."
  }
}

variable "memory_mb" {
  description = "RAM in megabytes"
  type        = number
  default     = 4096

  validation {
    condition     = var.memory_mb >= 1024 && var.memory_mb <= 8192
    error_message = "Memory must be between 1024 and 8192 MB."
  }
}

variable "disk_gb" {
  description = "Boot disk capacity of the selected Ubuntu Box"
  type        = number
  default     = 40

  validation {
    condition     = var.disk_gb == 40
    error_message = "The selected Ubuntu Box has a fixed 40 GiB boot disk. This variable does not resize it."
  }
}

variable "network" {
  description = "VirtualBox network adapter type"
  type        = string
  default     = "nat"

  validation {
    condition     = var.network == "nat"
    error_message = "This configuration currently supports NAT networking only."
  }
}

variable "cloud_init_user" {
  description = "Non-root Linux user created by cloud-init"
  type        = string
  default     = "devops"
}

variable "ssh_public_key_path" {
  description = "Path to the local SSH public key"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_host_port" {
  description = "Mac host port forwarded to SSH port 22 in the VM"
  type        = number
  default     = 2222
}
