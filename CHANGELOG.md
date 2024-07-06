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
- Fixes invalid usage of Phoenix LiveView streams by moving the flashes outside the stream container.
- Fixes a bit of a visual issue when loading on non LV pages by setting opacity to 0.
- New feature: arbitrary severity levels other than `:info` and `:error`.
- Various refactorings and cleanups.
- Fix required LV version to 0.20.
- Added proper TypeScript types.
- Added customization for the container class.
