#!/bin/bash
# ==============================================================================
# PostgreSQL Standby Auto-Rebuild Script
# ==============================================================================
# Description: Automatically rebuilds a corrupted or out-of-sync PostgreSQL 
#              standby node by cloning it from the active primary.
# Usage:       Should be run as a cron job or systemd timer on standby nodes.
# Dependencies: repmgr, postgresql, systemctl
# ==============================================================================

set -euo pipefail

LOG_FILE="/var/log/postgresql/auto-rebuild.log"
PG_VERSION="17"
PG_DATA_DIR="/var/lib/postgresql/17/main"
PG_WAL_DIR="/var/lib/postgresql/17/wal"
REPMGR_CONF="/etc/postgresql/17/main/repmgr.conf"
HEALTH_CHECK_INTERVAL=60

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

check_postgresql_health() {
    if pg_isready -U postgres -h localhost -p 5432 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

check_node_role() {
    local role=$(sudo -u postgres repmgr -f "$REPMGR_CONF" cluster show 2>/dev/null | grep "$(hostname)" | awk '{print $3}')
    echo "$role"
}

is_primary_active() {
    local primary_ip=$(grep "primary_host" "$REPMGR_CONF" | cut -d"'" -f2)
    if pg_isready -U postgres -h "$primary_ip" -p 5432 > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

rebuild_standby() {
    log "Starting standby rebuild process for $(hostname)"

    # Stop PostgreSQL
    systemctl stop postgresql

    # Remove corrupted data
    rm -rf "$PG_DATA_DIR"/*
    rm -rf "$PG_WAL_DIR"/*

    # Clone from active primary
    local primary_ip=$(grep "primary_host" "$REPMGR_CONF" | cut -d"'" -f2)
    sudo -u postgres repmgr -h "$primary_ip" \
        -U repmgr \
        -d repmgr \
        -f "$REPMGR_CONF" \
        standby clone \
        --force

    # Start PostgreSQL
    systemctl start postgresql

    # Register as standby
    sudo -u postgres repmgr -f "$REPMGR_CONF" standby register

    log "Standby rebuild completed successfully"
}

main() {
    log "Running health check for $(hostname)"

    # Skip if this is primary node
    local role=$(check_node_role)
    if [[ "$role" == "primary" ]]; then
        log "Node is primary, skipping rebuild"
        exit 0
    fi

    # Check if PostgreSQL is healthy
    if check_postgresql_health; then
        log "PostgreSQL is healthy, no action needed"
        exit 0
    fi

    log "PostgreSQL is unhealthy, attempting recovery"

    # Check if primary is still active
    if ! is_primary_active; then
        log "Primary is also down. Manual intervention required"
        exit 1
    fi

    # Attempt rebuild
    rebuild_standby

    # Verify rebuild
    if check_postgresql_health; then
        log "Standby successfully rebuilt and healthy"
    else
        log "Standby rebuild failed, manual intervention required"
        exit 1
    fi
}

# Run main function
main