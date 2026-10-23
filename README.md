# Get More Ram
A simple [StosSign](https://github.com/stossy11/StosSign) wrapper app that allows you to enable "Increased Memory Limit" for your sideloaded apps without using Xcode.

## Fork: configurable anisette & authentication headers

Since Apple's October 2026 GrandSlam change, sign-in fails with the old macOS headers (-80045, -22411, no 2FA code). This fork makes everything configurable from **Settings → Authentication**:

- **Anisette Server**: pick a server from a list, add your own, reorder/delete, and optionally fall back to the other servers when the selected one fails.
- **Server List (JSON)**: fetch servers from a URL (default `https://servers.sidestore.io/servers.json`). Accepts `{"servers": [{"name", "address"}]}`, an array of `{"name", "address"|"url"}` objects, or an array of URLs.
- **Client Info / User-Agent**: presets (Windows/iTunes, which SideStore users report working, plus the previous macOS values), free editing, or the anisette server's own `/v3/client_info`. Applied to anisette provisioning, GrandSlam sign-in and the 2FA requests.

StosSign is vendored in `Packages/StosSign` with a small patch: User-Agent override, handling of Apple's auto-pushed 2FA challenge (`hsc=409` with no `au`, see [SideSign#5](https://github.com/SideStore/SideSign/pull/5)), fresh anisette between 2FA steps, and readable errors when Apple returns non-plist responses. Sign-in progress is shown in the "Debugging" section of the sign-in sheet (with a "Copy Logs" button), including each GrandSlam step's `ec`/`hsc`/`au`.

Other patches, based on what was observed in October 2026:
- gsa.apple.com answers a large share of requests with an HTML 503 page regardless of their content, so GrandSlam and provisioning requests are retried on 503.
- The anisette identity (adi.pb) is re-provisioned when the server or Client-Info changes: Apple rejects provisioning with `-29003 environment mismatch` when the Client-Info doesn't match the server's ADI (e.g. Windows Client-Info with a Mac ADI server). The Windows/iTunes identity provisioned with `ani.sidestore.app` / `ani.sidestore.io`.
- GsService2 requests use the headers and `cpd` from [AltSign#61](https://github.com/rileytestut/AltSign/pull/61), and fresh anisette is fetched before `apptokens`.
- SMS 2FA lists the trusted phone numbers (`GET /auth`) like SideStore's apple-private-apis, falling back to the legacy request. Apple currently answers 403 there.

Known issue: with the Windows identity, 2FA and the second sign-in succeed but `apptokens` may return `-80046 "This action cannot be completed at this time"`.

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
