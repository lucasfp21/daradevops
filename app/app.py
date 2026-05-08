from http.server import BaseHTTPRequestHandler, HTTPServer
import os

APP_NAME = os.getenv("APP_NAME", "default-app")
APP_AUTHOR = os.getenv("APP_AUTHOR", "unknown")
APP_VERSION = os.getenv("APP_VERSION", "0")

MESSAGE = f"""
App: {APP_NAME}
Author: {APP_AUTHOR}
Version: {APP_VERSION}
"""

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type','text/plain')
        self.end_headers()
        self.wfile.write(MESSAGE.encode())

server = HTTPServer(('0.0.0.0', 9999), Handler)

print("Server running on port 9999")
server.serve_forever()