# Changelog

## 1.2.1

Changes since the previous public release, 1.1.0:

- Add optional app-window dimming with `dimmingEnabled` and `dimmingOpacity` (default off; default opacity 0.35).
- Optionally leave pass-through views undimmed with `dimmingExcludesPassthroughViews`, preserving UIKit touch delivery.
- Detect rounded Titanium wrappers, individual corners, filled shape-layer masks, configured capsule buttons, and rounded clipping ancestors.
- Add `dimmingCutoutShapes` overrides for circles, capsules, rounded rectangles, and automatic detection.
- Track moving cutouts, preserve overlapping clear regions, and remove the overlay on completed dismissal. UIKit retains its native presentation and system/zoom animations.
- Correct first-show grouped TableView spacing with a guarded native sizing pass after appearance; preserve explicit content insets and offsets.
- Add Classic/Alloy examples, geometry and lifecycle fixtures, and detailed API/validation documentation.

The intermediate 1.1.1 and 1.2.0 development builds were not published as GitHub releases. Requires iOS 26+ and Titanium SDK 13.4.1.GA+.

## 1.1.0

- Add pass-through views and native popover background colors.
- Allow visible anchors beneath undimmed sheets while preserving the sheet as presentation owner.

## 1.0.0

- First public release: native anchored action sheets and custom-content popovers, ordinary/bar-item sources, optional native zoom, scroll-inset control, and Classic/Alloy examples.
