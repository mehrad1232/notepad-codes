# NOVA Native Browser

A standalone iPhone browser targeting iPhone 5s and iOS 12.5.8. The installed app has no runtime dependency on a Windows PC, personal server, remote Chromium instance, or cloud service.

## Product architecture
- UIKit interface with a local WKWebView engine supplied by iOS.
- Address bar, back/forward, reload, saved bookmarks, and recent browsing history.
- Bookmarks and history are stored locally using UserDefaults.
- Dark interface with cyan accents; arm64 and iOS 12.0 deployment target.
- Optional jailbreak tweak sources are separate and are not required to run the IPA.

## Compatibility boundary
On iOS 12, WKWebView uses the version of WebKit shipped by iOS 12. NOVA can improve the browser interface and add selected JavaScript compatibility shims, but it cannot replace Apple's WebKit with modern Chromium or guarantee that every current website will work. Some modern sites may still show JavaScript/client-side errors.

## Build unsigned IPA
GitHub Actions builds an unsigned arm64 IPA on a macOS runner. The IPA must be signed before installation (for example, with Sideloadly). The build computer is needed only to compile/package the app; it is not needed after installation.

## Project layout
- ios/ — standalone iPhone app.
- tweak/ — optional jailbreak integration; not required for normal app use.
- .github/workflows/ios-build.yml — unsigned IPA build.

NOVA does not include a cloud browser or a Windows-hosted runtime.
