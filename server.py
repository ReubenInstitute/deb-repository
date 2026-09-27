#!/usr/bin/env python3
import http.server
import ssl
import os

repo_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(repo_dir)

cert_file = os.path.join(repo_dir, 'localhost.crt')
key_file = os.path.join(repo_dir, 'localhost.key')

server_address = ('127.0.0.1', 8443)
handler = http.server.SimpleHTTPRequestHandler

httpd = http.server.HTTPServer(server_address, handler)

context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
context.load_cert_chain(cert_file, key_file)
httpd.socket = context.wrap_socket(httpd.socket, server_side=True)

print(f"Starting HTTPS server at https://127.0.0.1:8443")
print(f"Serving from: {repo_dir}")
print("Press Ctrl+C to stop")

try:
    httpd.serve_forever()
except KeyboardInterrupt:
    print("\nShutting down...")
    httpd.shutdown()
