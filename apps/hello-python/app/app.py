from http.server import BaseHTTPRequestHandler, HTTPServer
import os

APP_NAME = os.getenv("APP_NAME")
APP_AUTHOR = os.getenv("APP_AUTHOR")
APP_VERSION = os.getenv("APP_VERSION")
APP_TOKEN = os.getenv("APP_TOKEN")

CONFIG_OK = all([APP_NAME, APP_AUTHOR, APP_VERSION])

if CONFIG_OK:
    MESSAGE = f"""
App: {APP_NAME}
Author: {APP_AUTHOR}
Version: {APP_VERSION}

Secret carregado: {'SIM' if APP_TOKEN else 'NAO'}
"""
else:
    MESSAGE = """
ERRO: ConfigMap nao carregado corretamente.
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