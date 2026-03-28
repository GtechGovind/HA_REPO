Build a complete production-grade High Availability (HA) infrastructure using Ansible for an on-premise environment (Ubuntu 25 compatible). The system must include application HA, PostgreSQL HA, monitoring, logging, auto-healing, and must be modular and reusable.

Architecture Requirements:

1. Application HA:

* Two application servers for now but should be scalable.
* Multiple applications running on internal ports (e.g., 9090, 9091, 9092, and so on ...).
* NGINX as an edge load balancer exposing ports (8080, 8081, 8082, and so on ...).
* Keepalived to manage a floating IP (VIP) for failover between app servers.
* Load balancing should distribute traffic across both servers (cross-node routing).
* Health checks must be implemented to avoid routing to unhealthy nodes.

2. Real-Time File Sync:

* Use lsyncd.
* Sync application directories (e.g., /var/www) between app nodes in near real-time using SSH key-based auth.

3. Database HA (PostgreSQL):

* Two DB servers (1 primary, 1 standby) - should be scalable but it will always multiple of 2 so witness is required.
* Streaming replication setup.
* Use repmgr for automatic failover and cluster management.
* Add a witness node (hosted on one of the app servers) to avoid split-brain.
* Keepalived for DB VIP.
* On primary failure:

  * standby should auto-promote.
  * VIP should move.
* Old primary should automatically rejoin as standby after recovery.

4. Auto-Rebuild (Self-Healing):

* Implement a script + systemd service to:
  * detect DB failure
  * wipe corrupted data
  * re-clone from current primary using pg_basebackup
  * rejoin cluster using repmgr
* Must run on boot and optionally via cron.
* Must dynamically detect current primary (not hardcoded).

5. PgBouncer:

* Install on app nodes.
* Applications should connect via PgBouncer instead of PostgreSQL.
* Use transaction pooling mode.
* Configure connection limits and pooling parameters.

6. Monitoring & Observability:

* Prometheus server (central).
* Node exporter on all nodes.
* PostgreSQL exporter.
* NGINX exporter.
* PgBouncer exporter.
* Loki + Promtail for centralized logging.
* Grafana dashboards:

  * PostgreSQL (replication lag, QPS, locks)
  * Node metrics (CPU, RAM, disk)
  * NGINX (RPS, errors)
  * PgBouncer (connections, pool usage)
  * JVM metrics (if Spring Boot used)

7. Health Checks:

* Spring Boot: /actuator/health
* Laravel: /health endpoint
* PostgreSQL: pg_isready script
* NGINX: /health endpoint
* Integrate health checks into Keepalived and load balancing.

8. Security & Best Practices:

* SSH key-based authentication
* Restrict pg_hba.conf
* Enable WAL archiving
* Use pgBackRest for backups
* Use systemd for all services
* Add firewall rules
* Ensure time sync

9. Ansible Requirements:

* Fully modular role-based structure.
* Separate roles for:

  * common
  * keepalived
  * nginx_lb
  * lsyncd
  * pgbouncer
  * postgresql (common, primary, standby, repmgr, witness, auto_rebuild)
  * monitoring (server/client)
  * app (springboot/laravel placeholders)
* Use templates for configs (Jinja2).
* Use group_vars for configuration.
* Inventory-based environment separation.

10. Deliverables:

* Full directory structure.
* All Ansible playbooks.
* All role task files.
* All templates (nginx, keepalived, pgbouncer, lsyncd, postgres configs).
* Systemd service files.
* Auto-rebuild script.
* Prometheus config.
* Example Grafana dashboards (JSON or description).
* Clear comments in code.

11. Additional Requirements:

* Everything must be highly configurable via variables.
* No hardcoded IPs (use inventory variables).
* Should be reusable for future HA systems (DB, apps, etc.).
* Follow production best practices and avoid shortcuts.

Goal:
The system should be self-healing, highly available, observable, and production-ready with minimal manual intervention.
