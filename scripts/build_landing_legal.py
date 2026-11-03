#!/usr/bin/env python3
"""Builds the public legal pages of the landing site from legal/*.md.

Google Play and the App Store both need a public privacy policy URL, and Play
needs a public page explaining how to delete an account. The app shows the same
Markdown in its Legal Center, so the website is generated from it: edit the
.md, run this, deploy landing/.

    pip install markdown
    python scripts/build_landing_legal.py

Writes landing/legal/{privacy,terms,security-disclosure}.html,
landing/delete-account.html and landing/open-app.html.
"""
from __future__ import annotations

import html
import pathlib

import markdown

ROOT = pathlib.Path(__file__).resolve().parents[1]
LEGAL = ROOT / "legal"
OUT = ROOT / "landing"

DOCS = {
    "privacy": ("PRIVACY_POLICY.md", "Privacy Policy"),
    "terms": ("TERMS_OF_USE.md", "Terms of Use"),
    "security-disclosure": ("SECURITY_DISCLOSURE_POLICY.md", "Security Disclosure Policy"),
}

STYLE = """
:root{--brand:#7377F9;--brand-deep:#4C57D6;--ink:#14161D;--muted:#565D6B;--bg:#F6F7FB;--surface:#FFFFFF;--border:#E4E7F0;--danger:#C53B3B}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{margin:0;background:var(--bg);color:var(--ink);font:16px/1.65 Inter,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
a{color:var(--brand-deep)}
header.top{background:var(--surface);border-bottom:1px solid var(--border)}
header.top .wrap{display:flex;align-items:center;justify-content:space-between;gap:16px;padding-block:14px}
.brand{display:flex;align-items:center;gap:10px;font-weight:800;color:var(--ink);text-decoration:none}
.brand img{border-radius:8px}
.wrap{max-width:820px;margin:0 auto;padding-inline:20px}
main.wrap{padding-block:36px 64px}
.doc{background:var(--surface);border:1px solid var(--border);border-radius:18px;padding:28px clamp(18px,4vw,44px)}
.doc h1{font-size:clamp(28px,4vw,38px);line-height:1.15;letter-spacing:-.02em;margin:0 0 12px;text-wrap:balance}
.doc h2{font-size:21px;margin:34px 0 8px;letter-spacing:-.01em}
.doc h3{font-size:17px;margin:24px 0 6px}
.doc p,.doc li{max-width:68ch}
.doc table{border-collapse:collapse;width:100%;font-size:14.5px;display:block;overflow-x:auto}
.doc th,.doc td{border:1px solid var(--border);padding:8px 10px;text-align:left;vertical-align:top}
.doc th{background:var(--bg)}
.doc hr{border:0;border-top:1px solid var(--border);margin:24px 0}
.doc code{background:var(--bg);padding:1px 5px;border-radius:5px}
.steps{counter-reset:s;list-style:none;padding:0}
.steps li{counter-increment:s;position:relative;padding-left:44px;margin:14px 0}
.steps li::before{content:counter(s);position:absolute;left:0;top:-2px;width:30px;height:30px;border-radius:50%;background:var(--brand);color:#fff;display:grid;place-items:center;font-weight:700;font-size:14px}
.note{background:var(--bg);border:1px solid var(--border);border-radius:12px;padding:14px 16px}
.btn{display:inline-block;background:var(--brand-deep);color:#fff;text-decoration:none;font-weight:700;padding:12px 20px;border-radius:12px}
footer.site{color:var(--muted);font-size:14px}
footer.site .wrap{display:flex;flex-wrap:wrap;gap:8px 18px;padding-block:24px}
footer.site a{color:var(--muted)}
"""

FOOT = """<footer class="site"><div class="wrap">
<span>&copy; 2026 SmartSpend</span>
<a href="/privacy">Privacy</a><a href="/terms">Terms</a><a href="/security-disclosure">Security disclosure</a>
<a href="/delete-account">Delete your account</a><a href="/#support">Contact</a>
</div></footer>"""


def page(title: str, description: str, body: str, canonical: str) -> str:
    return f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{html.escape(title)} · SmartSpend</title>
<meta name="description" content="{html.escape(description)}">
<link rel="canonical" href="https://smaartspend.com{canonical}">
<link rel="icon" type="image/png" href="/assets/logo.png">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
<style>{STYLE}</style>
</head>
<body>
<header class="top"><div class="wrap">
<a class="brand" href="/"><img src="/assets/logo.png" width="30" height="30" alt=""> SmartSpend</a>
<a href="/#support">Contact</a>
</div></header>
<main class="wrap"><article class="doc">
{body}
</article></main>
{FOOT}
</body>
</html>
"""


def build_docs() -> None:
    (OUT / "legal").mkdir(exist_ok=True)
    for slug, (src, title) in DOCS.items():
        md = (LEGAL / src).read_text(encoding="utf-8")
        # The header block ("**App:** ...", "**Effective Date:** ...") is one
        # field per line: keep the line breaks (Markdown would join them).
        md = "\n".join(
            line + "  " if line.startswith("**") and ":**" in line else line
            for line in md.splitlines()
        )
        body = markdown.markdown(md, extensions=["tables", "sane_lists"])
        (OUT / "legal" / f"{slug}.html").write_text(
            page(title, f"SmartSpend {title}.", body, f"/{slug}"), encoding="utf-8"
        )


DELETE = """
<h1>Delete your SmartSpend account</h1>
<p>You can delete your SmartSpend account at any time. Deleting it removes your account and all
the data stored with it on our servers. It cannot be undone.</p>

<h2>In the app (fastest)</h2>
<ol class="steps">
<li>Open SmartSpend and sign in.</li>
<li>Go to <b>Settings</b>, then <b>Security</b>.</li>
<li>Tap <b>Delete account</b> and confirm.</li>
</ol>
<p>Your account is deleted straight away and you receive a confirmation email.</p>

<h2>Without the app</h2>
<p>If you no longer have the app, email <a href="mailto:admin@smaartspend.com?subject=Account%20Deletion%20Request">admin@smaartspend.com</a>
from the email address you registered with, with the subject <b>Account Deletion Request</b>.
We confirm within 2 business days and complete the deletion within 30 days.</p>

<h2>What is deleted</h2>
<ul>
<li>Your account: name, email address, password and sign-in sessions.</li>
<li>Everything stored with your account on our servers.</li>
</ul>
<p class="note">Budgets, transactions and goals you keep only on your phone stay on the phone until you
uninstall SmartSpend. Crash reports, which never contain your financial data, expire after at most
90 days. See the <a href="/privacy">Privacy Policy</a> for details.</p>
"""

OPEN_APP = """
<h1>Open this in the SmartSpend app</h1>
<p>This link is meant to open inside the SmartSpend app on your phone.</p>
<ol class="steps">
<li>Open this link on the phone where SmartSpend is installed.</li>
<li>If it still opens in the browser, open SmartSpend and sign in: you'll find the same screen there.</li>
</ol>
<p>Don't have the app yet? <a href="/#download">SmartSpend is coming soon to the App Store and Google Play.</a></p>
<p><a class="btn" href="/">Go to smaartspend.com</a></p>
"""


def main() -> None:
    build_docs()
    (OUT / "delete-account.html").write_text(
        page("Delete your account", "How to delete your SmartSpend account and its data.", DELETE, "/delete-account"),
        encoding="utf-8",
    )
    (OUT / "open-app.html").write_text(
        page("Open in the app", "Open this link in the SmartSpend app.", OPEN_APP, "/open-app"),
        encoding="utf-8",
    )
    print("Built landing/legal/*.html, landing/delete-account.html, landing/open-app.html")


if __name__ == "__main__":
    main()
