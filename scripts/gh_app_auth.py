#!/usr/bin/env python3
"""
gh_app_auth.py — Get a short-lived GitHub installation token for agent-chatroom-bot.

Usage:
    python3 gh_app_auth.py           # prints token to stdout
    python3 gh_app_auth.py --json    # prints full response as JSON

Reads config from /root/.openclaw/workspace/projects/agent-chatroom/secrets/.gitignore.txt
Reads PEM from the path specified in that config file.

Token lifetime: 60 minutes. After expiry, re-run.
"""

import json
import subprocess
import sys
import time
from pathlib import Path

CONFIG_PATH = Path("/root/.openclaw/workspace/projects/agent-chatroom/secrets/.gitignore.txt")


def load_config():
    cfg = {}
    for line in CONFIG_PATH.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        k, _, v = line.partition("=")
        cfg[k.strip()] = v.strip()
    return cfg


def make_jwt(app_id: str, pem_path: str) -> str:
    """Sign a JWT with the App's private key (RS256, valid 10 minutes)."""
    header = {"alg": "RS256", "typ": "JWT"}
    now = int(time.time())
    payload = {
        "iat": now - 60,           # 60s clock-skew buffer
        "exp": now + 10 * 60,       # 10 minutes (GitHub max)
        "iss": app_id,
    }
    b64 = lambda d: __import__("base64").urlsafe_b64encode(
        json.dumps(d, separators=(",", ":")).encode()
    ).rstrip(b"=").decode()
    signing_input = f"{b64(header)}.{b64(payload)}".encode()

    # Use openssl for signing (system has it; no extra deps needed)
    sig = subprocess.run(
        ["openssl", "dgst", "-sha256", "-sign", pem_path],
        input=signing_input,
        capture_output=True,
        check=True,
    ).stdout
    import base64
    sig_b64 = base64.urlsafe_b64encode(sig).rstrip(b"=").decode()
    return f"{signing_input.decode()}.{sig_b64}"


def exchange_for_installation_token(jwt: str, installation_id: str) -> dict:
    import urllib.request
    req = urllib.request.Request(
        f"https://api.github.com/app/installations/{installation_id}/access_tokens",
        method="POST",
        headers={
            "Authorization": f"Bearer {jwt}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "agent-chatroom-bot",
        },
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode())


def main():
    cfg = load_config()
    jwt = make_jwt(cfg["APP_ID"], cfg["PEM_PATH"])
    result = exchange_for_installation_token(jwt, cfg["INSTALLATION_ID"])

    if "--json" in sys.argv:
        print(json.dumps(result, indent=2))
    else:
        print(result["token"])


if __name__ == "__main__":
    main()