DevOps Lab: Journey & Troubleshooting Log

This document chronicles the real-world challenges encountered while building a local, KVM-based DevOps lab on an Ubuntu host, along with the engineering solutions applied.

Phase 1: Infrastructure as Code (Terraform & Libvirt)

1. Missing ISO Generation Tool

Symptom: Terraform failed to create the Cloud-Init ISO disk with the error exec: "mkisofs": executable file not found in $PATH.

Root Cause: The Ubuntu host lacked the utility required by Terraform to generate the virtual CD-ROM containing the Cloud-Init user data.

Fix: Installed the required package on the host: sudo apt install genisoimage -y.

2. AppArmor Permission Denied

Symptom: Virtual machines failed to boot with Could not open 'rocky9-base.qcow2': Permission denied.

Root Cause: Ubuntu's native AppArmor security module prevented the QEMU process from reading the dynamically provisioned Terraform storage volumes.

Fix: Disabled dynamic security labeling in the hypervisor by setting security_driver = "none" in /etc/libvirt/qemu.conf and restarted the libvirtd service.

3. Libvirt DHCP Blocked by Host Firewall

Symptom: VMs booted but never received IP addresses (Terraform timed out waiting for lease; virsh net-dhcp-leases returned empty).

Root Cause: Ubuntu's default firewall (ufw) drops NAT forwarding traffic by default, blocking Libvirt's internal dnsmasq DHCP server.

Fix: Added UFW rules to allow traffic in/out on the virtual bridge (e.g., virbr1) and changed the DEFAULT_FORWARD_POLICY to "ACCEPT" in /etc/default/ufw.

4. Rocky Linux 9 Boot Freeze (CPU Architecture)

Symptom: The VM boot process froze indefinitely at probing EDD (edd=off to disable) ...ok in the VNC/Spice console.

Root Cause: Modern RHEL/Rocky 9 requires at least x86-64-v2 CPU microarchitecture. Libvirt's default generic virtual CPU (qemu64) does not meet this requirement, causing a silent boot failure.

Fix: Updated the Terraform libvirt_domain configuration to use <cpu mode="host-passthrough">, exposing the host's physical Intel i5 CPU directly to the guest.

5. Terraform Output Crashing

Symptom: Terraform crashed with Invalid index when trying to output the IP addresses of the nodes.

Root Cause: Because we set wait_for_lease = false to debug the boot sequence, Terraform reached the output block before the VMs had acquired IPs from the DHCP server.

Fix: Removed the dynamic Terraform output block and relied on native hypervisor tooling (sudo virsh net-dhcp-leases lab_net) to discover IPs post-deployment.

Phase 2: Configuration Management (Ansible)

6. Locale Encoding Error

Symptom: Ansible ping failed with Ansible requires the locale encoding to be UTF-8; Detected ISO8859-1.

Root Cause: The host terminal session was not exporting UTF-8 variables, crashing Ansible's Python backend.

Fix: Exported LC_ALL=en_US.UTF-8 and LANG=en_US.UTF-8, and made it permanent via sudo locale-gen en_US.UTF-8.

7. Cloud-Init SSH Key Injection Failure

Symptom: Ansible ping returned Permission denied (publickey). Journalctl inside the VM showed sshd: no hostkeys available -- exiting.

Root Cause: A race condition on the first boot caused sshd to crash before it generated host keys. Because sshd was down, Cloud-Init skipped injecting the devops SSH public key.

Fix: Generated the keys internally (ssh-keygen -A), restarted sshd, and manually pushed the host key using ssh-copy-id combined with a temporary Cloud-Init fallback password.

8. DNS Resolution & Sudo Password Missing

Symptom: Playbook failed on k8s-node with Missing sudo password and on ops-node with Curl error (6): Could not resolve host.

Root Cause: Due to the SSH crash (Challenge #7), Cloud-Init never finalized the NOPASSWD sudoers rule on the k8s-node. Furthermore, systemd-resolved on the host wasn't routing DNS properly through the NAT bridge.

Fix: Used Ansible ad-hoc commands to set DNS to 8.8.8.8 (nmcli con modify), restarted NetworkManager, and ran the playbook with the -K flag to manually supply the sudo password.

9. Missing Core Services in Minimal Images

Symptom: The Ensure Firewalld is installed and running task failed with Could not find the requested service firewalld.

Root Cause: The generic cloud qcow2 image is heavily stripped down and does not include firewalld by default.

Fix: Updated the base-setup.yml playbook to explicitly dnf install the firewalld package prior to attempting to start the service.
