Local DevOps Lab Project

Project Overview

This project aims to build a production-grade, fully automated DevOps and Platform Engineering lab on a local machine (Ubuntu host, 16GB RAM, 256GB SSD). To maximize resource efficiency without relying on cloud providers (AWS, GCP, Azure), this lab utilizes lightweight, open-source alternatives that map directly to enterprise tools.

The primary goal is to establish a fundamental, practical understanding of DevOps concepts, CI/CD pipelines, GitOps, and infrastructure automation.

Current Project Status

Current Phase: Entering Phase 2: Configuration Management (Ansible)
Completed Phase: Phase 1: Infrastructure as Code (Terraform)

Phase 1 Summary: Infrastructure as Code

In Phase 1, we successfully pushed past the hardest parts of local KVM automation, including host hypervisor nuances and OS-specific boot requirements. We established a declarative infrastructure pipeline using Terraform to spin up our virtual environment.

What We Achieved

Host Preparation: * Configured the Ubuntu host with KVM/QEMU and Libvirt.

Adjusted host firewall (UFW) settings to allow Libvirt's internal DHCP server (dnsmasq) to route traffic properly to the virtual network bridge.

Bypassed AppArmor dynamic labeling restrictions to allow QEMU to read dynamically created storage volumes.

Automated Provisioning (Terraform): * Utilized the dmacvicar/libvirt Terraform provider to define and provision two virtual machines (ops-node and k8s-node).

Created a private NAT network (lab_net) strictly for internal lab communication.

Utilized Rocky Linux 9 Generic Cloud (qcow2) images for an enterprise-grade (RHEL-compatible) foundation.

Cloud-Init Automation:

Generated Cloud-Init ISOs dynamically via Terraform to inject a dedicated devops user.

Injected ed25519 SSH public keys into the VMs on boot, enabling immediate, passwordless SSH access and preparing the nodes for Ansible.

Hardware & Architecture Alignment: * Identified that modern Rocky Linux 9 requires x86-64-v2 CPU architecture.

Configured Terraform to pass through the host's Intel i5 CPU (host-passthrough) to satisfy the boot sequence requirements, preventing kernel panics on boot.

The State of the Infrastructure

The lab currently consists of two running virtual machines accessible via SSH using the injected lab_key.

ops-node (4GB RAM, 2 vCPU):

IP Address: 10.10.10.200

Purpose: Will host Docker, Gitea (Version Control), and a CI/CD runner.

k8s-node (6GB RAM, 2 vCPU):

IP Address: (Assigned via DHCP, verifiable via virsh net-dhcp-leases lab_net)

Purpose: Will host K3s (Lightweight Kubernetes) and ArgoCD for GitOps deployments.

Next Steps: Phase 2 (Ansible)

With the baseline infrastructure running and accessible via SSH, we will transition to Configuration Management.

Objectives for Phase 2:

Create an Ansible inventory.ini file.

Write a base-setup playbook to update the OS package caches.

Automate the configuration of SELinux and Firewalld.

Automate the installation of Docker and Docker Compose on the ops-node.
