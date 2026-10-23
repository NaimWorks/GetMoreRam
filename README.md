# Get More Ram
A simple [StosSign](https://github.com/stossy11/StosSign) wrapper app that allows you to enable "Increased Memory Limit" for your sideloaded apps without using Xcode.

## Fork: configurable anisette & authentication headers

Since Apple's October 2026 GrandSlam change, sign-in fails with the old macOS headers (-80045, -22411, no 2FA code). This fork makes everything configurable from **Settings → Authentication**:

- **Anisette Server**: pick a server from a list, add your own, reorder/delete, and optionally fall back to the other servers when the selected one fails.
- **Server List (JSON)**: fetch servers from a URL (default `https://servers.sidestore.io/servers.json`). Accepts `{"servers": [{"name", "address"}]}`, an array of `{"name", "address"|"url"}` objects, or an array of URLs.
- **Client Info / User-Agent**: presets (Windows/iTunes, which SideStore users report working, plus the previous macOS values), free editing, or the anisette server's own `/v3/client_info`. Applied to anisette provisioning, GrandSlam sign-in and the 2FA requests.

StosSign is vendored in `Packages/StosSign` with a small patch: User-Agent override, handling of Apple's auto-pushed 2FA challenge (`hsc=409` with no `au`, see [SideSign#5](https://github.com/SideStore/SideSign/pull/5)), fresh anisette between 2FA steps, and readable errors when Apple returns non-plist responses. Sign-in progress is shown in the "Debugging" section of the sign-in sheet.

# How to use
1. Sideload this app
2. Go to settings, sign in your account that you used to sign the app you want to enable "Increased Memory Limit"
3. Go to "App IDs" page
4. Tap Refresh
5. Tap the app you want to enable "Increased Memory Limit"
6. Tap "Add Increased Memory Limit"
7. Reinstall the app from SideStore/AltStore
8. Check if you have "Increased Memory Limit"

# Credits
Stossy11 - For StosSign.
SideStore - Anisette Data fetching codes are stolen from SideStore
