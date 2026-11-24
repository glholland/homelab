"""forever-armory: type a WoW: Forever character's name, get a report of everything
Blizzard's API has on them. Standard library only.

  GET /                 the lookup form
  GET /c/<first-surname> the report (fetched server-side, cached for CACHE_SECONDS)
  GET /healthz          liveness

Environment: BLIZZARD_CLIENT_ID, BLIZZARD_CLIENT_SECRET (required), WOW_REGION (us),
PORT (8080), CACHE_SECONDS (300). The secret never reaches the browser."""
import base64, concurrent.futures, html, json, os, re, threading, time, unicodedata
import urllib.error, urllib.parse, urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import report

REGION = os.environ.get("WOW_REGION", "us")
API = f"https://{REGION}.api.blizzard.com"
NAMESPACE = f"profile-forever-{REGION}"
CACHE_SECONDS = int(os.environ.get("CACHE_SECONDS", "300"))
TIMEOUT = 15

# A Forever character is "First Surname": letters only (accents allowed), no realm.
NAME_PART = r"[^\W\d_]{2,12}"
NAME_RE = re.compile(rf"^\s*({NAME_PART})[\s-]+({NAME_PART})\s*$")


class Upstream(Exception):
    def __init__(self, status, message):
        super().__init__(message)
        self.status = status


_token = {"value": None, "expires": 0.0}
_token_lock = threading.Lock()


def token():
    with _token_lock:
        if _token["value"] and time.time() < _token["expires"] - 60:
            return _token["value"]
        cid, secret = os.environ.get("BLIZZARD_CLIENT_ID"), os.environ.get("BLIZZARD_CLIENT_SECRET")
        if not cid or not secret:
            raise Upstream(500, "The server has no Blizzard credentials configured.")
        req = urllib.request.Request("https://oauth.battle.net/token", data=b"grant_type=client_credentials",
                                     headers={"Authorization": "Basic " + base64.b64encode(f"{cid}:{secret}".encode()).decode(),
                                              "Content-Type": "application/x-www-form-urlencoded"})
        try:
            with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
                body = json.load(r)
        except urllib.error.HTTPError as err:  # never echo the response: it can quote the client ID
            raise Upstream(502, f"Blizzard refused the server's credentials (HTTP {err.code}).") from None
        _token.update(value=body["access_token"], expires=time.time() + body.get("expires_in", 3600))
        return _token["value"]


def get(path):
    """One profile request. Returns decoded JSON, {} for a 404."""
    url = f"{API}{path}?namespace={NAMESPACE}&locale=en_US"
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token()})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as r:
            return json.load(r)
    except urllib.error.HTTPError as err:
        if err.code == 404:
            return {}
        raise Upstream(502, f"Blizzard's API answered HTTP {err.code}.") from None
    except (urllib.error.URLError, TimeoutError):
        raise Upstream(504, "Blizzard's API did not answer in time.") from None


def slug(first, surname):
    return urllib.parse.quote(f"{first}-{surname}".lower())


def fetch_all(character_slug):
    base = f"/profile/wow/character/{character_slug}"
    summary = get(base)
    if not summary:  # no such character: don't spend 15 more requests finding out
        return {"summary": {}}
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        futures = {k: pool.submit(get, base + suffix) for k, suffix in report.SECTIONS.items() if k != "summary"}
        return {"summary": summary, **{k: f.result() for k, f in futures.items()}}


_cache, _cache_lock = {}, threading.Lock()


def character_page(character_slug):
    with _cache_lock:
        hit = _cache.get(character_slug)
        if hit and time.time() - hit[0] < CACHE_SECONDS:
            return 200, hit[1]
    data = fetch_all(character_slug)
    if not data["summary"]:
        return 404, None
    page = report.render(data)
    with _cache_lock:
        if len(_cache) > 200:
            _cache.clear()
        _cache[character_slug] = (time.time(), page)
    return 200, page


STYLE = """:root{--bg:#f6f4ef;--panel:#fffdf8;--ink:#221d16;--muted:#6f675b;--line:#e2dccf;--accent:#8a5a12;--bad:#b3261e}
@media (prefers-color-scheme:dark){:root{--bg:#14120f;--panel:#1d1a16;--ink:#ece6da;--muted:#a59c8c;--line:#352f27;--accent:#e0b25c;--bad:#ff8a80}}
*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);color:var(--ink);font:16px/1.5 system-ui,-apple-system,"Segoe UI",sans-serif;padding:16px}
.box{width:100%;max-width:440px;background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:28px}
h1{font-family:Georgia,"Times New Roman",serif;margin:0 0 4px;font-size:1.9rem}p{color:var(--muted);margin:0 0 18px}
label{display:block;font-weight:600;margin-bottom:6px}input{width:100%;font:inherit;padding:10px 12px;border:1px solid var(--line);border-radius:9px;background:var(--bg);color:var(--ink)}
button{margin-top:14px;width:100%;font:inherit;font-weight:700;padding:10px;border:0;border-radius:9px;background:var(--accent);color:var(--bg);cursor:pointer}
button[disabled]{opacity:.6;cursor:wait}.err{color:var(--bad);margin:12px 0 0}small{display:block;margin-top:14px;color:var(--muted)}"""


def form_page(message="", value=""):
    err = f'<p class="err" role="alert">{html.escape(message)}</p>' if message else ""
    return f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Forever Armory</title><style>{STYLE}</style></head><body><main class="box">
<h1>Forever Armory</h1><p>Everything Blizzard's API knows about a World of Warcraft: Forever character.</p>
<form action="/lookup" method="get" onsubmit="this.querySelector('button').disabled=true;this.querySelector('button').textContent='Looking up...'">
<label for="name">Character name</label>
<input id="name" name="name" value="{html.escape(value)}" placeholder="First Surname, e.g. Zyn Thief" autocomplete="off" required autofocus>
<button type="submit">Build report</button>{err}</form>
<small>Data is as of the character's last logout. Characters appear once they have logged in.</small></main></body></html>"""


class Handler(BaseHTTPRequestHandler):
    server_version = "forever-armory"

    def send(self, status, body, ctype="text/html; charset=utf-8", headers=None):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.send_header("Referrer-Policy", "no-referrer")
        for k, v in (headers or {}).items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        url = urllib.parse.urlsplit(self.path)
        if url.path == "/healthz":
            return self.send(200, "ok", "text/plain")
        if url.path == "/":
            return self.send(200, form_page())
        if url.path == "/lookup":
            name = urllib.parse.parse_qs(url.query).get("name", [""])[0]
            m = NAME_RE.match(unicodedata.normalize("NFC", name))
            if not m:
                return self.send(400, form_page("Enter a first name and a surname, like Zyn Thief.", name[:40]))
            return self.send(303, "", headers={"Location": "/c/" + slug(*m.groups())})
        if url.path.startswith("/c/"):
            raw = urllib.parse.unquote(url.path[3:])
            m = NAME_RE.match(unicodedata.normalize("NFC", raw.replace("-", " ")))
            if not m:
                return self.send(400, form_page("That isn't a First Surname character name.", raw[:40]))
            try:
                status, page = character_page(slug(*m.groups()))
            except Upstream as err:
                return self.send(err.status, form_page(str(err), raw.replace("-", " ")[:40]))
            if status == 404:
                return self.send(404, form_page(f"No Forever character named {m.group(1).title()} {m.group(2).title()}. "
                                                "Check the spelling (accents matter) and that they have logged in recently.",
                                                f"{m.group(1)} {m.group(2)}"))
            return self.send(200, page, headers={"Cache-Control": f"private, max-age={CACHE_SECONDS}"})
        self.send(404, form_page("Page not found."))

    def log_message(self, fmt, *args):  # one line per request, no query strings
        print(f'{self.address_string()} "{self.command} {urllib.parse.urlsplit(self.path).path}" {args[1] if len(args) > 1 else ""}', flush=True)


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "8080"))
    print(f"forever-armory listening on :{port} (region {REGION})", flush=True)
    ThreadingHTTPServer(("", port), Handler).serve_forever()
