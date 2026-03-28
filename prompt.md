Act as a senior DevOps architect with 15+ years of experience and design a **production-grade High Availability (HA) infrastructure using Ansible** for an **on-premise environment optimized for Ubuntu 25**.

This solution must be **infra-focused only** — it should NOT handle application deployment logic. Applications will run independently on internal ports and should be treated as external services.

The system must be **fully automated, modular, scalable, self-healing, highly configurable, and reusable across multiple systems (applications, databases, services)**.

---

# 🎯 OBJECTIVE

Build a reusable HA infrastructure platform that provides:

* Application-level High Availability (infra layer only)
* PostgreSQL High Availability
* Real-time file synchronization
* Connection pooling (PgBouncer)
* Observability (metrics, logs, dashboards)
* Auto-healing (node rebuild)
* Web-based DB management (pgAdmin)
* Strong health checks
* Security and production hardening

The platform should act as a **generic HA foundation** that any application can plug into.

---

# 🏗️ ARCHITECTURE REQUIREMENTS

## 1. Application HA Layer (Infra Only)

* Minimum **2 application nodes (scalable to N nodes)**.
* Applications run externally on **internal ports (e.g., 9090, 9091, 9092, ...)**.
* The system must NOT deploy or manage application code.

### Responsibilities:

* Use **NGINX as edge load balancer**:

  * Expose configurable ports (8080, 8081, ...)
  * Route traffic to internal services
* Use **Keepalived**:

  * Provide a **floating IP (VIP)**

### Requirements:

* Cross-node routing (load balancing across all nodes)
* Health-based routing:

  * If a service is unhealthy → no traffic
* Support:

  * dynamic upstream configuration
  * easy addition/removal of nodes via inventory

---

## 2. Real-Time File Synchronization

* Use **lsyncd**
* Sync configurable directories (e.g., `/var/www`, `/opt/apps`)
* Near real-time (inotify-based)
* SSH key-based authentication

---

## 3. PostgreSQL HA Layer

* Minimum **2 DB nodes (primary + standby)**
* Must support scaling to multiple replicas

### Must include:

* Streaming replication
* **repmgr** for cluster management
* **witness node (on app server)** to prevent split-brain
* **Keepalived for DB VIP**

### Failover behavior:

* Automatic standby promotion
* VIP reassignment
* Old primary auto-rejoins as standby

---

## 4. Auto-Healing (Self-Rebuild)

Implement an automated DB recovery system:

* Detect failure
* Validate node role (avoid rebuilding primary)
* Remove corrupted data
* Re-clone from active primary
* Rejoin via repmgr

### Requirements:

* Bash script + systemd
* Runs:

  * on boot
  * via cron (optional)
* Dynamic master detection
* Logging enabled

---

## 5. PgBouncer (Connection Pooling)

* Deploy on all app nodes
* Apps connect via PgBouncer

### Requirements:

* Transaction pooling
* Configurable limits
* Multi-DB support
* Secure authentication

---

## 6. Monitoring & Observability

### Metrics:

* Prometheus (central)
* Exporters:

  * node_exporter
  * postgres_exporter
  * nginx_exporter
  * pgbouncer_exporter

### Logging:

* Loki + Promtail

### Visualization:

* Grafana dashboards:

  * PostgreSQL metrics
  * Node metrics
  * NGINX metrics
  * PgBouncer metrics

---

## 7. Health Checks

Provide standardized health validation:

* HTTP-based health endpoints (configurable path like `/health`)
* PostgreSQL → `pg_isready`

### Integration:

* NGINX upstream filtering
* Keepalived failover decisions
* Monitoring alerts

---

## 8. pgAdmin (DB Management)

* Deploy pgAdmin (web UI)
* Connect via DB VIP
* Configurable:

  * port
  * credentials
* Secure access (auth + optional IP restriction)

---

## 9. Security & Hardening

* SSH key-based access only
* Disable password login
* Harden PostgreSQL access
* Enable WAL archiving
* Integrate pgBackRest (design-level)
* Firewall configuration
* Time sync (chrony)

---

## 10. Ansible Design

### Roles:

* common
* keepalived
* nginx_lb
* lsyncd
* pgbouncer
* postgresql:

  * common
  * primary
  * standby
  * repmgr
  * witness
  * auto_rebuild
* monitoring:

  * server
  * client
* pgadmin

### Requirements:

* Fully variable-driven
* No hardcoded values
* Jinja2 templates
* Inventory-based scaling
* Idempotent execution

---

## 11. Deliverables

Provide:

* Full Ansible project structure
* Inventory
* Playbooks
* Roles (tasks + templates)
* systemd services
* Auto-rebuild script
* Monitoring configs
* pgAdmin setup
* Documentation/comments

---

## 12. Additional Requirements

* Easy horizontal scaling (add nodes via inventory)
* Environment support (dev/stage/prod)
* Configurable:

  * ports
  * users
  * paths
  * credentials
* Reusable across:

  * app clusters
  * DB clusters
  * future services

---

# 🚀 EXPECTED OUTCOME

A **clean, infra-only HA platform** that:

* Provides load balancing + failover
* Manages DB HA fully
* Self-heals nodes
* Is observable and secure
* Can be reused across multiple independent application systems

This should reflect **real-world SRE-grade infrastructure design**, not a tightly coupled deployment setup.
