# NOVA Amethyst / Jailbreak Tweak

This is an optional SpringBoard-side companion package, not the browser engine. NOVA Browser works without it. The tweak adds a SpringBoard URL scheme hook so a user can launch NOVA from supported URL-open flows.

## Build
Install Theos and an iOS 12.0 SDK, then run:
```sh
make package
```
The package targets arm64 and iOS 12.0. Install the resulting .deb using Sileo or another package manager.

## Notes
- This does not patch Safari or replace WebKit.
- No private APIs are required for the standalone browser.
- Validate against the exact jailbreak/bootstrap before installing. Keep a device backup.
