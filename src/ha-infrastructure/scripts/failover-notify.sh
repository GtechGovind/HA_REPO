#!/bin/bash
# ==============================================================================
# Database Failover Notification Script
# ==============================================================================
# Description: Notifies administrators when a database failover occurs.
#              - Triggered by repmgr or keepalived event hooks.
#              - Sends alerts via email, Slack, or webhook.
# ==============================================================================

# Configure your notification endpoint here
WEBHOOK_URL="${FAILOVER_WEBHOOK_URL:-https://hooks.slack.com/services/YOUR/WEBHOOK/URL}"

notify_failover() {
    local node_name=$(hostname)
    local event_type="$1"
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: Database failover event '$event_type' detected on $node_name"

    echo "$message"
    
    if [[ -n "$WEBHOOK_URL" && "$WEBHOOK_URL" != "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" ]]; then
        curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"$message\"}" "$WEBHOOK_URL"
    fi
}

if [[ $# -ge 1 ]]; then
    notify_failover "$1"
else
    notify_failover "Unknown Failover Event"
fi
