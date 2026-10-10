# 1.0.0 release validation

Version 1.0.0 preserves the native implementation tested in development version 0.1.2. The release updates version metadata and documentation. The release package is rebuilt from the tagged source with Titanium SDK 13.4.1.GA and Xcode 27.1 beta, and checked for ZIP integrity, embedded identity/version, and device arm64 plus simulator arm64/x86_64 slices. The build uses a process-local Titanium Xcode detection override because SDK 13.4.1.GA declares support only through Xcode 26; the installed SDK and global Xcode selection are unchanged. These build/package checks are separate from the historical runtime evidence below.

# Historical 0.1.2 validation

## Manual total-inset control (2026-10-09)

The current release defaults custom-content popovers to `autoAdjustScrollViewInsets: false`. UIKit's per-scroll-view contentInsetAdjustmentBehavior is set to never while presented and its original policy is restored after completed dismissal. The module does not assign contentInset or contentOffset. Automatic behavior is an explicit opt-in.

Native device/simulator compilation and a real Titanium consumer test passed with SDK 13.4.1.GA and Xcode 27.1 beta on iOS 27.0. A controlled diagnostic fixture supplied an additional safe area of top 20/bottom 10. Manual top 52/bottom 80 produced adjustedContentInset 52/80 and offset -52; manual 0/0 produced adjustedContentInset 0/0 and offset 0. The automatic opt-in produced adjustedContentInset 72/90 for the same manual 52/80 values. Both setContentInsets() and the user's contentInsets property assignment were exercised. Reopening shared content with automatic behavior restored the automatic policy. The synthetic safe area, logging, and diagnostic timers are removed from the distribution.

A natural popover fixture had safeAreaInsets 0/0 and already reported adjustedContentInset 52/80 in the old automatic mode. Thus the user's photographs alone do not prove that their top gap comes from safe-area addition. Layout offsets, explicit top insets, and section/header spacing remain separate from this policy.

Apply explicit table insets when presenting reused content: Titanium can recreate a native TableView after its close lifecycle. See example/manualInsets.js. Real-device layout, keyboard adjustments, and grouped-section styling remain separate validation. This release does not claim a correction for the previously investigated cancelled-zoom source visibility issue.

## Historical 0.1.1 validation

The historical same-version rebuild added native zoom and required iOS 26+. Earlier checks below describe the original 0.1.1 binary where explicitly marked.

Historical 0.1.1 build environment: Titanium SDK 13.4.1.GA, Xcode 27.1 beta, iOS 16 deployment target, Objective-C ARC.

Completed:

- Native module compilation/package for iOS arm64 and iOS Simulator arm64/x86_64.
- ZIP CRC/integrity and embedded module identity/version checks.
- Defined native symbols for module, action-sheet proxy, popover proxy, content controller, and source resolver.
- Classic and Alloy controller JavaScript syntax checks.
- Alloy iOS compilation in an isolated temporary fixture.
- App-local module integration and simulator consumer build.

Runtime checks use an isolated app on the iOS 27.0 iPhone 18 Pro Max simulator. The 0.1.1 animated regression passed 40 shows and 40 dismissals: 32 custom-content popovers and 8 action sheets, cycling toolbar buttons, navigation buttons, ordinary buttons, and an avatar view. It tests hide during opening, hide from the show event, duplicate hide/show requests, immediate reopening from the dismiss event, and live content resizing. No rejected-transition or detached-controller warning appeared in the successful run.

Manual inspection confirmed an arrowless custom-content glass popover anchored to the avatar view. The normal-view popover can differ from the bar-button morph; UIKit selects the animation and material. The regression is included as `example/rapidLifecycle.js`; copy it to a Classic app's `Resources/app.js` to run it. The current example now leaves arrow directions at UIKit's default.

The earlier 0.1.0 smoke checks also exercised live source changes and six source/presentation combinations. Real-device rapid gesture dismissal and visual parity with the reference recording remain unverified.

Additional interaction coverage:

- Visually compare animated presentation/dismissal to the reference recording on iOS 26 and 27, including real devices.
- Verify action selection and outside-tap dismissal events, disabled/cancel/destructive actions, and dismissOnOutsideTap false.
- Exercise TableView/ListView/ScrollView/custom native content, keyboard, rotation, iPad positioning, source removal/recycling, and owner-window teardown.
- Verify VoiceOver, Reduce Motion, Reduce Transparency, Dynamic Type, and dark appearance.

Compilation and smoke tests do not prove every source's glass morph appearance. No global installation, GitHub publication, or release is performed by the module build.

## Arrowless animation investigation (2026-10-05)

An isolated Swift UIKit app, without Titanium or this module, tested an ordinary UIButton and a standard toolbar UIBarButtonItem with `sourceItem`, `animated: true`, and arrow directions 0 versus any on iOS 27.0. CADisplayLink sampled presentation-layer geometry/opacity throughout the presentation container, including UIKit's separate chrome. Ordinary-button arrowless presentation produced one distinct sample, versus 29 with default arrows; dismissal still produced changing samples. The standard toolbar item produced changing chrome samples with either setting. An initial content-only measurement missed the toolbar's separate chrome and was superseded by this container-wide test.

This reproduces a suppressed ordinary-button entrance in UIKit despite an asynchronous animated completion callback; it does not establish that every source has the same limitation. The previous 40-cycle regression verified lifecycle completion and event counts; it did not prove visual animation. Examples now omit the forced zero setting. No native animator or workaround was added, and the 0.1.1 native binary is unchanged. iOS 26 and real-device behavior were not checked in this investigation.

## iOS 26+ scope (2026-10-07)

Current source deployment targets are iOS 26.0 for every Xcode build configuration. Pre-iOS-26 support is outside the module scope. Earlier 0.1.1 build evidence predates this target change. The current same-version rebuild targets iOS 26+. The retained isMorphingSupported method returns true on all supported systems.

## Native zoom implementation (2026-10-07)

Native device arm64 and simulator arm64/x86_64 compilation passed using Xcode 27.1 beta and Titanium SDK 13.4.1.GA. Classic/controller JavaScript syntax and isolated Alloy iOS compilation passed. In a diagnostic Titanium consumer on iOS 27.0, UIKit called the zoom source-view providers for a normal button and avatar view during presentation and dismissal. The requested bar-item provider was not observed in that run; UIKit continues to manage bar-item presentation through sourceItem. A manual inspection confirmed the avatar custom-content bubble. The 40-cycle diagnostic lifecycle regression (32 zoom popovers and 8 action sheets) and invalid/unsupported transition validation passed on iOS 26.5 and iOS 27.0. These event counts are distinct from visual animation proof.

The runnable lifecycle example now compares 16 zoom popovers, 16 default system popovers, and 8 action sheets across all four source types. It then exposes manual zoom controls. Native interactive gesture recognition/cancellation, disabled dismissal, source removal/recycling, iPad, accessibility, and real-device parity still require interaction testing. A simulator drag attempt did not dismiss the popover; do not claim verified interactive drag behavior from this test. UIKit's native policy decides which zoom gestures begin.

Final clean-binary consumer run on iOS 27.0 passed 40 shows/40 dismissals across 16 zoom popovers, 16 default system popovers, and 8 action sheets. It also passed invalid/unsupported transition validation, live source changes within view/bar-item kinds, and hiding the avatar before zoom dismissal then restoring it. The final consumer's MinimumOSVersion and the module library's build commands both specify 26.0. No diagnostic provider logging remains. Source removal/recycling and interactive gesture parity remain unverified.
