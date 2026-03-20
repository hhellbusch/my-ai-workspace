#!/usr/bin/env python3
"""
HTTPS file server for serving ISOs over the network.

Listens on port 6183 by default with a self-signed TLS certificate.
The certificate is auto-generated via openssl if not already present.

Usage:
    python3 iso-server.py /path/to/iso/directory
    python3 iso-server.py /path/to/iso/directory --port 6183
    python3 iso-server.py /path/to/iso/directory --cert my.crt --key my.key

AI-DISCLOSURE: This script was generated with AI assistance.
"""

import os
import ssl
import sys
import subprocess
import argparse
from http.server import HTTPServer, SimpleHTTPRequestHandler
from pathlib import Path

DEFAULT_PORT = 6183
DEFAULT_CERT = "server.crt"
DEFAULT_KEY  = "server.key"


def generate_self_signed_cert(cert_file: str, key_file: str) -> None:
    """Generate a self-signed RSA certificate using openssl."""
    print(f"[*] Generating self-signed certificate ...")
    try:
        subprocess.run(
            [
                "openssl", "req",
                "-x509",
                "-newkey", "rsa:4096",
                "-keyout", key_file,
                "-out", cert_file,
                "-days", "365",
                "-nodes",
                "-subj", "/CN=localhost/O=ISO Server/C=US",
            ],
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        print(f"[!] openssl failed:\n{exc.stderr}")
        sys.exit(1)
    except FileNotFoundError:
        print("[!] 'openssl' not found. Install it or supply --cert / --key pointing to existing files.")
        sys.exit(1)

    print(f"    cert : {cert_file}")
    print(f"    key  : {key_file}")


class QuietHandler(SimpleHTTPRequestHandler):
    """SimpleHTTPRequestHandler with cleaner log lines."""

    def log_message(self, fmt, *args):  # noqa: D102
        print(f"  {self.address_string()} - {fmt % args}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Serve a directory over HTTPS on a given port (default 6183).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "directory",
        nargs="?",
        default=".",
        help="Directory to serve (defaults to current directory)",
    )
    parser.add_argument(
        "--port", "-p",
        type=int,
        default=DEFAULT_PORT,
        help="TCP port to listen on",
    )
    parser.add_argument(
        "--cert",
        default=DEFAULT_CERT,
        help="Path to PEM certificate file (auto-generated if missing)",
    )
    parser.add_argument(
        "--key",
        default=DEFAULT_KEY,
        help="Path to PEM private key file (auto-generated if missing)",
    )
    parser.add_argument(
        "--host",
        default="0.0.0.0",
        help="Interface to bind to",
    )
    args = parser.parse_args()

    # -- Validate directory ----------------------------------------------------
    serve_dir = Path(args.directory).resolve()
    if not serve_dir.exists():
        print(f"[!] Directory not found: {serve_dir}")
        sys.exit(1)

    # -- Certificate -----------------------------------------------------------
    cert_missing = not os.path.exists(args.cert)
    key_missing  = not os.path.exists(args.key)

    if cert_missing or key_missing:
        if not cert_missing or not key_missing:
            # One file exists but not the other — likely a mistake
            print("[!] Only one of --cert / --key exists. Provide both or neither.")
            sys.exit(1)
        generate_self_signed_cert(args.cert, args.key)
    else:
        print(f"[*] Using existing certificate: {args.cert}")

    # -- SSL context -----------------------------------------------------------
    ssl_ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_ctx.load_cert_chain(certfile=args.cert, keyfile=args.key)

    # -- HTTP server -----------------------------------------------------------
    os.chdir(serve_dir)

    httpd = HTTPServer((args.host, args.port), QuietHandler)
    httpd.socket = ssl_ctx.wrap_socket(httpd.socket, server_side=True)

    print(f"\n[*] Serving  : {serve_dir}")
    print(f"[*] Listening: https://{args.host}:{args.port}/")
    print("[*] Press Ctrl+C to stop.\n")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[*] Server stopped.")


if __name__ == "__main__":
    main()
