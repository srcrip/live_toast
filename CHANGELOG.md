# Changelog

All notable changes to this project will be documented in this file.

Note that the versions prior to `0.6.0` are very unstable.

## [v0.1.0] (2024-03-06)

🚀 Initial release.

## [v0.2.0] (2024-03-08)

Bug fixes:
- JS.Show on the flashes now correctly toggles them to display flex instead of block
- The component functions properly when used in non-liveviews

## [v0.3.0] (2024-03-12)

Bug fixes:
- Fixing quite a few little problems here and there
- Adding more configuration

## [v0.4.0] (2024-05-11)

Massive overhaul of look and feel.

## [v0.4.1] (2024-05-11)

Demo repo bug fixing.

## [v0.4.2] (2024-05-15)

Tightening up a few bugs found during the creation of the demo.

## [v0.4.3] (2024-05-15)

Fix implementation of `send_toast`.

## [v0.5.0] (2024-05-16)

New Public API.

## [v0.6.0] (2024-05-17)

Fixed Hex release. Some files were missing from the build.

## [v0.6.1] (2024-05-18)

Remove a `console.log` from the JS bundle.

## [v0.6.2] (2024-05-19)

Releasing new bundle (meant to compile it in `v0.6.1`).

## [v0.6.3] (2024-05-22)

- Documentation updates.

## [v0.6.4] (2024-07-10)

- More documentation updates.
- Fixes invalid usage of Phoenix LiveView streams by moving the flashes outside the stream container.
- Fixes a bit of a visual issue when loading on non LV pages by setting opacity to 0.
- New feature: arbitrary severity levels other than `:info` and `:error`.
- Various refactorings and cleanups.
- Fix required LV version to 0.20.
- Added proper TypeScript types.
- Added customization for the container class.

## [v0.7.0] (2024-12-26) 🎄

- Big fix to longstanding issue where toasts don't work properly across navigations: #28
- Added gettext internationalization from #16 (thanks @elephantoss)
- A couple other random cleanups and docs changes.

## [v0.8.0] (2024-02-14) ❤️

- Fixed typespecs from #26 (thanks @wkirschbaum)
- Added `:top_center` and `:bottom_center` positions in #29 (thanks @nallwhy)
- Feature: infinite duration toasts from #31 (thanks @vanderhoop)
- Readme fixes in #32
- Fix earlier weirdness with gettext usage in 0.7.0 in #34 (thanks @neilberkman)
- Fix docs source ref in #39 (thanks @Flo0807)

## [v0.9.0] (2026-07-24)

## Highlights

- Add a browser JavaScript API: `addToast/3` requests server-rendered toasts from frontend code.
- Add programmatic dismissal with `LiveToast.dismiss_toast/2` and the composable `LiveToast.dismiss/1` action for custom components.
- Pause timed toasts while hovered or focused, then resume with their remaining duration.
- Support persistent toasts with `duration: 0` or `:infinity`.
- Add `:top_center` and `:bottom_center` host positions.
- Allow a default custom toast component function on `toast_group`, with per-toast overrides.
- Pass application metadata through to custom toast components.
- Make connection-state notices customizable, replaceable through slots, or fully disableable.
- Add recipes and documentation for the new APIs and customization paths.
