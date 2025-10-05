#!/usr/bin/env python3
"""
Role Explorer - Progressive Web App for NixOS Role-based Configuration
"""

import http.server
import socketserver
import json
import subprocess
import sys
import os
from pathlib import Path
from urllib.parse import parse_qs, urlparse

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
WEBAPP_DIR = Path(__file__).parent.parent / 'webapp'

class RoleExplorerHandler(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        parsed = urlparse(self.path)

        # Serve PWA files
        if parsed.path == '/' or parsed.path == '/index.html':
            self.serve_file(WEBAPP_DIR / 'index.html', 'text/html')
        elif parsed.path == '/styles.css':
            self.serve_file(WEBAPP_DIR / 'styles.css', 'text/css')
        elif parsed.path == '/themes.css':
            self.serve_file(WEBAPP_DIR / 'themes.css', 'text/css')
        elif parsed.path == '/theme-menu-styles.css':
            self.serve_file(WEBAPP_DIR / 'theme-menu-styles.css', 'text/css')
        elif parsed.path == '/app.js':
            self.serve_file(WEBAPP_DIR / 'app.js', 'application/javascript')
        elif parsed.path == '/manifest.json':
            self.serve_file(WEBAPP_DIR / 'manifest.json', 'application/manifest+json')
        elif parsed.path == '/sw.js':
            self.serve_file(WEBAPP_DIR / 'sw.js', 'application/javascript')
        elif parsed.path == '/icon.svg':
            self.serve_file(WEBAPP_DIR / 'icon.svg', 'image/svg+xml')
        elif parsed.path == '/icon-192.png' or parsed.path == '/icon-512.png':
            # Serve SVG as fallback for PNG icons
            self.serve_file(WEBAPP_DIR / 'icon.svg', 'image/svg+xml')
        # API endpoints
        elif parsed.path == '/api/roles':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(self.get_roles()).encode())
        elif parsed.path == '/api/hosts':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(self.get_hosts()).encode())
        else:
            self.send_error(404)

    def serve_file(self, filepath, content_type):
        """Serve a static file"""
        try:
            with open(filepath, 'rb') as f:
                content = f.read()
            self.send_response(200)
            self.send_header('Content-type', content_type)
            self.send_header('Cache-Control', 'no-cache')
            self.end_headers()
            self.wfile.write(content)
        except FileNotFoundError:
            self.send_error(404)

    def get_roles(self):
        """Scan for available roles"""
        roles_dir = Path('modules/roles')
        if not roles_dir.exists():
            return []

        roles = []
        for role_file in roles_dir.glob('*.nix'):
            if role_file.name == 'default.nix':
                continue

            role_name = role_file.stem
            # Try to extract description from file
            content = role_file.read_text()
            description = f"Role: {role_name}"

            # Count packages (simple heuristic)
            packages = content.count('pkgs.')

            roles.append({
                'name': role_name,
                'description': description,
                'packages': packages,
                'file': str(role_file)
            })

        return roles

    def get_hosts(self):
        """Scan for configured hosts"""
        hosts_dir = Path('hosts')
        if not hosts_dir.exists():
            return []

        hosts = []
        for host_dir in hosts_dir.iterdir():
            if not host_dir.is_dir():
                continue

            config_file = host_dir / 'default.nix'
            if not config_file.exists():
                continue

            # Try to extract roles from parts/hosts.nix
            host_roles = self.get_host_roles(host_dir.name)

            hosts.append({
                'name': host_dir.name,
                'roles': host_roles,
                'config': str(config_file)
            })

        return hosts

    def get_host_roles(self, hostname):
        """Extract roles for a specific host"""
        hosts_config = Path('parts/hosts.nix')
        if not hosts_config.exists():
            return []

        content = hosts_config.read_text()
        # Simple parsing - look for roles = [ ... ]
        # This is a basic implementation
        import re
        pattern = rf'{hostname}.*?roles\s*=\s*\[(.*?)\]'
        match = re.search(pattern, content, re.DOTALL)
        if match:
            roles_str = match.group(1)
            roles = re.findall(r'"([^"]+)"', roles_str)
            return roles
        return []

with socketserver.TCPServer(("", PORT), RoleExplorerHandler) as httpd:
    print(f"╭─────────────────────────────────────────╮")
    print(f"│  NixOS Role Explorer PWA                │")
    print(f"│  Running at http://localhost:{PORT:<6}     │")
    print(f"│                                         │")
    print(f"│  💡 Tip: Install as an app!            │")
    print(f"│  Click the install button in browser   │")
    print(f"╰─────────────────────────────────────────╯")
    print("\nPress Ctrl+C to stop")
    httpd.serve_forever()
