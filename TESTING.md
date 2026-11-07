# NotiFilter test log

## Build 1.0.0 — first public release

**Built:** 2026-11-07
**Device:** iPhone 11 Pro Max, iOS 18.4.1 (22E252), Dopamine 3 + RootHide
**Install:** RootHide deb installed over the previous test build; SpringBoard restarted.
**Installed version:** 1.0.0

### Builds

- Rootless: `builds/com.burc334.notifilter_1.0.0_iphoneos-arm64.deb`
  SHA-256: `15eef89f667c8c742af0e55da478658868d5a4fa594bd04d69cd3ae326365af6`
- RootHide: `builds/com.burc334.notifilter_1.0.0_iphoneos-arm64e.deb`
  SHA-256: `a82e265d143aa039d47e2d78ceaf74d6919e7dd0ec8c5cb7d2cea4a37042e207`

### Verification

- Mac unit tests: **57 passed, 0 failed**.
- Rootless and RootHide packages build from a neutral temporary path.
- RootHide package: `iphoneos-arm64e`, version `1.0.0`.
- Rootless package: `iphoneos-arm64`, version `1.0.0`.
- Preference bundle `Info.plist` and About footer report `1.0.0`.
- RootHide payload contains the tweak dylib, filter plist, preference bundle, PreferenceLoader entry, and package icons.
- No diagnostic hooks, probe preferences, debug logs, dSYMs, or local build paths are present in the final payload.
- RootHide package installed successfully; SpringBoard is running.
- No NotiFilter or SpringBoard crash observed during the final install.

### Feature coverage

| Area | Status |
|---|---|
| RootHide install / upgrade / SpringBoard load | Passed |
| Block | Device-confirmed in 0.5.2 |
| Mute | Device-confirmed in 0.5.2 |
| Schedule toggle | Device-confirmed in 0.6.3 |
| Filter matching and action precedence | Mac unit tests |
| Schedule matching and overnight windows | Mac unit tests |
| Schedule editor and execution | Intentionally not device-tested |
| Critical-alert fail-open guard | Mac unit tests and source review |
| Import/export schema, merge, and validation | Mac unit tests |
| Blocked-notification history | Mac unit tests and source review |
| History and import/export Settings screens | Not device-confirmed |
| Critical-alert delivery | Requires an entitled app; not device-tested |
| Rootless installation | No rootless test device available |

The rootless build is expected to work on iOS 18+ rootless jailbreaks.
