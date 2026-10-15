"""Tiny localhost receiver: Studio POSTs script source to /<Name>.lua and it's written into studio/."""
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import re

HERE = Path(__file__).parent

class H(BaseHTTPRequestHandler):
    def do_POST(self):
        name = self.path.strip("/")
        if not re.fullmatch(r"[A-Za-z0-9_]+\.(lua|luau)", name):
            self.send_response(400); self.end_headers(); return
        body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        (HERE / name).write_bytes(body)
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
    def log_message(self, *a): pass

HTTPServer(("127.0.0.1", 8793), H).serve_forever()
