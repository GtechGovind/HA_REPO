# High Availability (HA) Infrastructure with Ansible

This repository provides a complete, production-ready Ansible-based orchestration for deploying a highly available infrastructure. It features a multi-layer architecture including load balancing, database clustering, and a full monitoring stack, optimized for **Ubuntu 22.04, 24.04 (Noble), and 25.04 (Plucky)**.

---

## 🏗️ Architecture Overview

The infrastructure is designed for zero single point of failure (SPOF):

- **Load Balancing (Application Layer)**:
  - **Keepalived**: Manages a Virtual IP (VIP) between Nginx nodes.
  - **Nginx**: High-performance reverse proxy and SSL termination.
  - **Lsyncd**: Real-time file synchronization across application nodes.

- **Database Layer**:
  - **PostgreSQL 17**: Latest stable database version with streaming replication.
  - **Repmgr**: Automated failover management, witness nodes, and cluster health.
  - **PgBouncer**: High-performance connection pooling for database clients.

- **Observability Layer**:
  - **Prometheus**: Time-series metrics collection.
  - **Grafana**: Advanced visualization with pre-configured dashboards (System, PostgreSQL, and Nginx VTS).
  - **Exporters**: Node Exporter, PostgreSQL Exporter, Nginx VTS Exporter, and PgBouncer Exporter.

---

## 🛠️ Detailed Setup Guide (For Beginners)

### 1. Prerequisites (Control Node)
Before starting, ensure your local machine (Control Node) has the following:
- **Operating System**: Linux or macOS.
- **Ansible 2.15+**: Install via pip: `pip install ansible`
- **SSH Key**: Generate an SSH key if you don't have one: `ssh-keygen -t rsa -b 4096`

### 2. Prepare Target Nodes (Servers)
- **OS**: Fresh Ubuntu 24.04 or 25.04 installation.
- **User**: A user named `atek` with passwordless sudo access on all servers.
- **SSH Access**: Copy your SSH public key to all nodes: `ssh-copy-id atek@<server-ip>`

### 3. Centralized Configuration
All configuration is centralized in ONE place. Edit `inventory/production/group_vars/all.yml` to match your environment:
- **Network**: Set your `app_vip` and `db_vip` (Virtual IPs).
- **PostgreSQL**: Customize version (default 17) and tuning parameters.
- **Monitoring**: All ports for Prometheus, Grafana, and Exporters are defined here.
- **Firewall**: The `allowed_ports` list in this file automatically configures UFW on all nodes.

### 4. Manage Secrets (Ansible Vault)
Sensitive data (passwords) MUST be encrypted. Follow these steps:

1. **Create the vault file**:
   ```bash
   ansible-vault create inventory/production/group_vars/all/vault.yml
   ```
2. **Add the following variables to the file**:
   ```yaml
   vault_postgres_password: "secure_password"
   vault_replication_password: "replication_password"
   vault_repmgr_password: "repmgr_password"
   vault_pgbouncer_password: "pgbouncer_password"
   vault_grafana_password: "admin_password"
   vault_keepalived_password: "vrrp_password"
   vault_pgadmin_password: "pgadmin_admin_password"
   ```
3. **Save and close**. You will be prompted for a vault password. Remember it!

### 5. Deployment
Run the main playbook to provision the entire stack:
```bash
ansible-playbook playbooks/site.yml --ask-vault-pass
```

### 6. Post-Installation Verification
Run the health check suite to ensure all components are communicating:
```bash
ansible-playbook playbooks/health-check.yml
```

---

## 📊 Port Reference Table

All ports are configurable in `inventory/production/group_vars/all.yml`.

| Component | Default Port | Purpose |
| :--- | :--- | :--- |
| SSH | 22 | Secure Shell Access |
| HTTP / HTTPS | 80 / 443 | Web Traffic (Nginx) |
| PostgreSQL | 5432 | Database Engine |
| PgBouncer | 6432 | Connection Pooler |
| Prometheus | 9090 | Metrics Collection |
| Grafana | 3000 | Visualization Dashboard |
| Alertmanager | 9093 | Alert Notifications |
| Node Exporter | 9100 | System Metrics |
| PG Exporter | 9187 | DB Metrics |
| Nginx VTS | 9113 | LB Metrics |
| PgBouncer Exp | 9127 | Pooler Metrics |
| Health Check | 8000 | Internal Health Probes |

---

## 🛡️ Security & Hardening

- **Firewall (UFW)**: Default-deny policy. Only ports listed in `all.yml` are allowed.
- **SSH**: Root login disabled, password authentication disabled, custom hardening applied.
- **Intrusion Prevention**: Fail2Ban enabled by default on all nodes.
- **Audit**: `auditd` configured for monitoring sensitive file changes.

---

## 🛠️ Operational Tasks

### Database Failover
Failover is handled automatically by **repmgr**. To manually switchover for maintenance:
```bash
sudo -u postgres repmgr standby switchover
```

### Self-Healing Standbys
Standby nodes include an auto-rebuild script (`/opt/ha-infrastructure/scripts/db-auto-rebuild.sh`) that automatically restores the standby from the primary if corruption is detected.

### Scaling
To add a new application node:
1. Add the host to the `app_nodes` group in `inventory/production/hosts.yml`.
2. Run: `ansible-playbook playbooks/scale-nodes.yml --limit <new_host>`

---

## 📝 License
This project is licensed under the MIT License.
