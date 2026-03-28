#!/usr/bin/env python3
"""
==============================================================================
Infrastructure Health Check Endpoint Script
==============================================================================
Description: A simple Python-based HTTP server that exposes health check
             endpoints for load balancer and external monitoring probes.
             - Responds with 200 OK if internal services are healthy.
             - Returns 503 Service Unavailable on failures.
==============================================================================
"""

import http.server
import socketserver
import subprocess

PORT = 8000

class HealthCheckHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            if self.check_health():
                self.send_response(200)
                self.end_headers()
                self.wfile.write(b"OK")
            else:
                self.send_response(503)
                self.end_headers()
                self.wfile.write(b"Service Unavailable")
        else:
            self.send_response(404)
            self.end_headers()

    def check_health(self):
        # Example: check if a specific process is running (e.g., nginx or postgres)
        # For simplicity, we just check if a certain port is open or a service is active
        try:
            # Check if common services are active (can be customized per node type)
            result = subprocess.run(['systemctl', 'is-active', 'nginx'], capture_output=True)
            if result.returncode == 0:
                return True
            result = subprocess.run(['systemctl', 'is-active', 'postgresql'], capture_output=True)
            if result.returncode == 0:
                return True
            return False
        except Exception:
            return False

if __name__ == "__main__":
    with socketserver.TCPServer(("", PORT), HealthCheckHandler) as httpd:
        print(f"Serving health check on port {PORT}")
        httpd.serve_forever()
