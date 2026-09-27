#!/usr/bin/env python3
import http.server
import os

repo_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(repo_dir)

server_address = ('0.0.0.0', 8000)
handler = http.server.SimpleHTTPRequestHandler

httpd = http.server.ThreadingHTTPServer(server_address, handler)

print(f"Starting HTTP server at http://0.0.0.0:8000")
print(f"Serving from: {repo_dir}")
print("Press Ctrl+C to stop")

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\nShutting down...")
    httpd.shutdown()
