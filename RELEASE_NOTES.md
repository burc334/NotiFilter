# NotiFilter 1.0.0

NotiFilter 1.0.0 is the first public release of the notification-filtering tweak for iOS 18.

## Highlights

- Filter notifications by app, or across all apps.
- Match title, subtitle, message, or all text.
- Match modes: Contains, Starts With, Ends With, Exact, Regex, and Always.
- Block, Mute, and Allow actions with deterministic precedence.
- Allow overrides Block and Mute; Block overrides Mute.
- Weekday and overnight schedules.
- Critical alerts are never filtered.
- Blocked-notification history with configurable count and day limits.
- Versioned JSON import/export with Merge and Replace flows.
- Native preference pane with no respring required for settings changes.
- Rootless and RootHide packages.

## Compatibility

| Build | Architecture | Compatibility |
|---|---|---|
| RootHide | `iphoneos-arm64e` | Tested on iOS 18.4.1 (Dopamine 3, RootHide) |
| Rootless | `iphoneos-arm64` | Expected to work on iOS 18+ rootless jailbreaks |

Tested on iOS 18.4.1 (Dopamine 3, RootHide) on iPhone 11 Pro Max. NotiFilter requires iOS 18.0 or later. The rootless build is expected to work on iOS 18+ rootless jailbreaks.

## Assets

- `com.burc334.notifilter_1.0.0_iphoneos-arm64e.deb`
- `com.burc334.notifilter_1.0.0_iphoneos-arm64.deb`
- `SHA256SUMS.txt`

## Install

1. Download the deb matching your jailbreak.
2. Install it with Sileo, Zebra, or Filza.
3. Respring after installation so SpringBoard loads the tweak and preference bundle.
4. Open **Settings → NotiFilter**, enable NotiFilter, and add your filters.
5. Tap **Apply** after changing settings. No respring is required for settings changes.

## Verification

Verify the downloaded deb against `SHA256SUMS.txt` before installing it.

## Notes

This release uses GitHub Releases and the GitHub Pages depiction. No APT repository is required.
