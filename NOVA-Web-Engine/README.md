# NOVA Web Engine

A dual-mode browser for legacy iOS devices (target: iPhone 5s / iOS 12.5.8): native WebKit for compatible sites, and remote Chromium rendering hosted on Windows 10 for sites that exceed the device's WebKit capabilities.

> This repository is an existing repository; NOVA is isolated under `NOVA-Web-Engine/` and does not replace its existing files.

## Components
- **NOVA iOS** — UIKit + WKWebView shell, local browsing, cloud-browser screen, settings and diagnostics.
- **NOVA Cloud** — Python FastAPI service controlling isolated Playwright Chromium contexts, screenshots and pointer/keyboard/scroll input.
- **NOVA Tweak** — optional Theos package scaffold for jailbroken iOS 12. It is separate from the standalone IPA.
- **CI** — unsigned iOS IPA build and cloud service checks.

## Important compatibility facts
- The iOS app's local engine is the system WKWebView. On iOS 12 this is old WebKit; JavaScript polyfills can fill selected missing APIs but cannot turn it into modern Chromium.
- Cloud mode runs the actual website in Chromium on the Windows PC and streams screenshots to the phone. It is remote rendering, not a WebKit upgrade.
- The IPA is unsigned by CI and must be signed for installation (e.g. Sideloadly). The iOS 12 target is arm64.
- The tweak is optional and does not inject code into Safari. It adds a small SpringBoard integration point; NOVA remains a standalone browser.

## Quick start — Windows 10
1. Install Python 3.11+ and Google Chrome (or let Playwright install its Chromium).
2. Open PowerShell in `NOVA-Web-Engine/cloud`.
3. Run `py -m venv .venv`, then `.\.venv\Scripts\Activate.ps1`.
4. Run `pip install -r requirements.txt`.
5. Run `playwright install chromium`.
6. Copy `.env.example` to `.env`, set a long `NOVA_API_TOKEN`, and set `NOVA_ALLOWED_ORIGINS` only if needed.
7. Run `uvicorn nova_cloud.main:app --host 0.0.0.0 --port 8765`.
8. Allow TCP 8765 through Windows Firewall on the Private profile only. Connect the iPhone and PC to a trusted network; enter the PC's LAN IP and token in NOVA.

Do not expose port 8765 directly to the public internet. Use a VPN or authenticated reverse proxy for remote access.

## Build the iOS IPA
GitHub Actions runs on macOS and creates an **unsigned** IPA artifact. Open `ios/project.yml` with XcodeGen or run the workflow manually. Deployment target is iOS 12.0.

## Build the jailbreak package
See `tweak/README.md`. Build with Theos on a supported macOS/Linux environment. Package installation requires a compatible package manager and jailbreak. The tweak is not required for the browser or cloud mode.

## Security
Cloud sessions are temporary and in-memory. Set a unique token, keep the server on a trusted LAN, do not share the token, and stop the service when not in use. Cloud browsing can access websites as the user; do not use it to access private intranet targets from untrusted clients.
