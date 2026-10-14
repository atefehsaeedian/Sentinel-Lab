# Terraform Ubuntu VM on VirtualBox

## 1. Overview

This project uses Terraform to provision and manage an Ubuntu Server virtual machine in Oracle VirtualBox using the `eran132/vbox` provider.

The configuration includes:
- Configurable VM name, CPU, memory, and network type.
- Cloud-init configuration for a non-root Linux user.
- SSH public-key authentication.
- SSH connection information through Terraform outputs.
- Infrastructure validation and idempotent plan verification.
- Safe instructions for destroying the lab VM.

## 2. Prerequisites

- macOS on an Intel host.
- Oracle VirtualBox installed.
- Terraform installed.
- An SSH key pair on the host.
- The Ubuntu Jammy Vagrant box at `images/ubuntu-jammy-amd64.box`.
- The generated cloud-init seed ISO at `cloud-init-seed.iso`.

The Ubuntu box and generated ISO are local files and are not committed to Git.

## 3. Project Files

- `versions.tf`: Terraform and provider requirements.
- `main.tf`: Virtual machine resource configuration.
- `variables.tf`: Input variables and validation rules.
- `outputs.tf`: VM name and SSH connection command.
- `cloud-init.yaml`: Cloud-init template.
- `cloud-init-seed/`: Seed metadata and user-data used to generate the ISO.
- `.terraform.lock.hcl`: Locked provider dependency versions.
- `.gitignore`: Excludes local, generated, and sensitive files.

## 4. Default Configuration

| Variable | Default | Description |
|---|---|---|
| `vm_name` | `tf-ubuntu-lab` | Virtual machine name |
| `cpu` | `2` | Number of virtual CPUs |
| `memory_mb` | `4096` | RAM in megabytes |
| `disk_gb` | `40` | Fixed capacity of the selected boot disk |
| `network` | `nat` | VirtualBox network type |
| `cloud_init_user` | `devops` | Non-root Linux username |
| `ssh_public_key_path` | `~/.ssh/id_ed25519.pub` | SSH public-key path |
| `ssh_host_port` | `2222` | Host port forwarded to guest SSH port 22 |

The selected Ubuntu box has a fixed 40 GiB boot disk. The `disk_gb` variable does not resize the disk.

## 5. Initialize and Validate

Run these commands from the project directory:

```bash
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the execution plan before applying any changes.

## 6. Apply the Configuration

```bash
terraform apply
```

Review the proposed actions and type `yes` only if you approve them.

## 7. Connect to the VM

Connect from the host using SSH:

```bash
ssh -i ~/.ssh/id_ed25519 -o IdentitiesOnly=yes -p 2222 devops@127.0.0.1
```

The SSH private key must remain on the host and must never be committed to Git.

## 8. Verify the VM

Check the Terraform outputs:

```bash
terraform output
```

Check the VM configuration in VirtualBox:

```bash
VBoxManage showvminfo tf-ubuntu-lab --machinereadable
```

Verify that Terraform detects no unexpected changes:

```bash
terraform plan -detailed-exitcode
```

Exit code `0` means no changes are required. Exit code `1` indicates an error, and exit code `2` indicates that changes are present.

## 9. Cloud-init

The `cloud-init.yaml` file is a Terraform template that accepts the VM hostname, Linux username, and SSH public key.

The existing VM also uses the locally generated `cloud-init-seed.iso`. The files in `cloud-init-seed/` contain the seed configuration used by that ISO.

If the hostname, username, or SSH key changes, regenerate the ISO and carefully review the planned changes. Changing a cloud-init file does not automatically update the contents of an already generated ISO.

## 10. Terraform State and Git Safety

Terraform state records the relationship between the configuration and the managed VM. Preserve the state files locally and back them up securely.

The following files and directories must not be committed:
- `.terraform/`
- `terraform.tfstate` and backup state files
- Terraform plan files
- Local variable files containing secrets
- SSH private keys
- The local Ubuntu box and generated ISO

The `.gitignore` file excludes these items from Git tracking.

The `.terraform.lock.hcl` file should be committed to help keep provider selections reproducible.

## 11. Destroy the Lab VM

**Warning:** Destroying the Terraform-managed VM can permanently delete the VM and data stored inside it.

Only if you intentionally want to remove `tf-ubuntu-lab`, inspect the destroy plan first:

```bash
terraform plan -destroy
```

If the plan includes only the intended lab resources, execute:

```bash
terraform destroy
```

Confirm the operation only after reviewing the plan.

Do not run `terraform destroy` when you want to preserve the VM. The existing `gateway`, `application`, and `monitoring` VMs are separate from this lab and must not be deleted.

## 12. Validation Results

The following checks have passed during project validation:

- `terraform fmt -check`
- `terraform validate`
- `terraform plan -detailed-exitcode` with exit code `0`

The VM was created and verified in VirtualBox, and SSH access using the `devops` user was confirmed.
