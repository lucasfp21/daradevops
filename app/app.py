# app.py
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type','text/plain')
        self.end_headers()
        self.wfile.write(b'hello world v2')

server = HTTPServer(('0.0.0.0', 9999), Handler)
print("Server running on port 9999")
server.serve_forever()