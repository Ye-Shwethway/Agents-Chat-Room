import urllib.request
import urllib.error
import sys
from pathlib import Path
import subprocess

WS = Path(__file__).resolve().parent.parent

def token() -> str:
    return subprocess.run(
        ["python3", str(WS / "scripts" / "gh_app_auth.py")],
        capture_output=True, text=True, check=True,
    ).stdout.strip()

method = sys.argv[1] if len(sys.argv) > 1 else "GET"
path = sys.argv[2] if len(sys.argv) > 2 else "/"

req = urllib.request.Request(
    f"https://api.github.com{path}",
    method=method,
    headers={
        "Authorization": f"token {token()}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "agent-chatroom-bot",
    },
)
try:
    with urllib.request.urlopen(req, timeout=20) as r:
        data = r.read()
        try:
            sys.stdout.write(data.decode('utf-8'))
        except UnicodeDecodeError:
            sys.stdout.write(data.decode('utf-8', errors='replace'))
except urllib.error.HTTPError as e:
    sys.stderr.write(f"ERROR {e.code}: {e.read().decode()}\n")
    sys.exit(1)