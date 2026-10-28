# 1.2.1 rounded cutout shapes

Automatic cutouts now follow the Titanium visual wrapper rather than relying only on the native touch target. The overlay uses public layer corner radii, masked corners, filled shape-layer masks, rounded ancestor clipping, and UIButton capsule configuration. Explicit `dimmingCutoutShapes` entries select circle, capsule, roundedRect, or auto without changing UIKit pass-through targets, presentation controllers, or system/zoom animations. Circle overrides are inscribed and centered; radii are validated and clamped. Shapes are converted through ordinary 2D layer transforms, compared by path geometry, and cleared separately to preserve overlapping holes. Complex alpha/image masks, continuous-corner curves, and 3D perspective are outside the exact-shape contract.

The developer confirmed the 1.2.1 build was working before requesting publication. This report supplements the checks below and does not establish exhaustive device/OS coverage. The public release is rebuilt from its exact tagged source commit; package identity, architectures, deployment targets, and the uploaded asset hash are verified separately.

Validation with Xcode 27.1 beta, Titanium SDK 13.4.1.GA, and iOS 27.0 Simulator:

- Device arm64 and simulator arm64/x86_64 compilation passed with minimum iOS 26.
- The production dimming-view geometry fixture passed 22 checks, including all original opacity/overlap/visibility/clipping/cleanup cases, Titanium-style wrappers around inner controls, individual rounded corners, shape-layer masks, configured UIKit capsules, all explicit shapes, zero/clamped radii, rounded ancestor clipping, and 2D rotation.
- A real Titanium consumer rejected 11 invalid override configurations before presentation, including wrong containers/entries, unknown shapes, missing/negative/nonfinite/nonnumeric radii, duplicate overrides, and non-pass-through views.
- The shape-enabled lifecycle fixture passed 40 shows/40 dismissals while cycling auto/circle/capsule/roundedRect, native zoom/system presentations, dimming off/zero opacity, immediate reopen/early hide requests, and action sheets.
- Simulator UI screenshots confirmed automatic rounded button/circular avatar cutouts without the previous rectangle corners, and explicit capsule/circle/roundedRect overrides. A pass-through Help tap updated the underlying label while the bubble stayed open; Close dismissed it before reopening with explicit shapes.

Physical-device gesture/cancellation parity, every UIKit configuration/mask, 3D perspective, iPad, and accessibility variations remain separate interaction checks. No global module installation or DateMaps changes were performed for this validation.

# 1.2.0 optional dimming overlay

Adds a noninteractive per-presentation UIKit overlay below native presentation containers, with optional pass-through cutouts. Native controller animations remain system-managed. Cutout tracking uses a weak display-link target and weak view references, stops on removal, and redraws only when geometry changes. Overlapping cutouts are cleared individually. Native transition-coordinator completions restore alpha on cancellation; cleanup removes the overlay before dismiss listeners can reopen the proxy.

Validated with Titanium SDK 13.4.1.GA and Xcode 27.1 beta:

- Native compilation/package: iOS device arm64 and simulator arm64/x86_64, minimum iOS 26.
- An isolated real Titanium consumer on iOS 27.0 passed 40 shows/40 dismissals, immediate reopen, early/duplicate hides, native zoom/system transitions, action sheets, dimming off, zero opacity, and optional exclusions. No module global install or DateMaps edits were needed.
- The isolated native geometry fixture passed 11 checks: noninteractive/accessibility configuration, opacity, clear/rounded/overlapping cutouts, hidden/moved/detached views, ancestor clipping, display-link removal, and full dimming without a display link.
- Four invalid opacity values (-0.1, 1.1, NaN, Infinity) were rejected through the real Titanium bridge before presentation.
- Simulator UI checks confirmed the clear pass-through Help button received a tap while the bubble remained open, movement updated the cutouts, a fully dimmed pass-through button still received a second tap, and both the content Close button and UIKit outside-dismiss region dismissed the bubble. The settled dimmed presentation was visually inspected.

These checks do not prove cancelled interactive drag behavior, physical-device animation parity, iPad positioning/rotation, keyboard/window teardown, or every accessibility setting. Cancellation restoration is implemented through UIKit transition-coordinator completion; a matched progressed/cancelled native gesture remains a device interaction check. Existing first-show TableView changes are preserved.

# 1.1.1 first-show TableView layout correction (2026-10-22)

The supplied DateMaps recording shows an extra gap below the table header on initial presentation, with footer actions clipped. Native measurements in the running iOS 27.0 simulator established that this was not a nonzero content inset: the event TableView had `contentInset` and `adjustedContentInset` of 0, offset `{0, 0}`, a 92-point table header, and a first-row Y of 127. `sectionHeaderTopPadding` was already 0. Re-registering the table header did not change the gap; a native `beginUpdates`/`endUpdates` sizing pass moved the first row to 92 while preserving the header height, insets, and offset.

An isolated real Titanium SDK 13.4.1.GA consumer with the released 1.1.0 module, an inset-grouped TableView, automatic-height header, native zoom transition, and persistent undimmed sheet reproduced the same 127-versus-92 geometry. A separate UIKit harness with minimal Titanium host stubs did not reproduce the baseline bug, so that harness alone is not regression proof; it did verify the candidate correction preserves explicit top/bottom insets 52/80 and content offset -52, as well as ordinary plain-table layout.

The patch refreshes each native table once from the content host's `viewDidAppear:` callback. A candidate in `viewDidLayoutSubviews` with a non-null window ran too early and failed the real Titanium regression; the appearance callback passed. A weak per-host table set guards reentrant layout and does not retain discarded tables. It does not hardcode a spacing adjustment, reload table data, change the application's inset opt-in, or reset content offsets. The module-only `example/firstShowTable.js` creates fresh grouped-table content for repeated visual checks. The final 1.1.1 candidate passed the real Titanium first-show regression: header height 92, first-row Y 92, zero content/adjusted insets, and offset zero. A second real Titanium run with automatic adjustment disabled preserved explicit insets top 52/bottom 80, adjusted insets 52/80, and offset -52; the first row remained at Y 92. Both used iOS 27.0, native zoom, and the persistent undimmed sheet. Native distribution compilation passed for device arm64 and simulator arm64/x86_64. Physical-device validation remains separate.

# 1.1.0 public release

This release combines the undimmed-sheet anchor fix, `passthroughViews`, and native popover `backgroundColor`. The DateMaps developer confirmed that the anchor fix and pass-through touches worked, and approved publication after the background-color addition. These reports do not establish exhaustive physical-device, iPad, accessibility, or OS-version coverage.

Release packaging rebuilds the iOS module from the clean release commit on `main`, verifies its 1.1.0 manifest and device arm64 / simulator arm64+x86_64 libraries, and records the source commit and final ZIP SHA-256 in the GitHub release. The runnable Classic and Alloy examples document the new options. Earlier same-version development packages must be replaced and consuming apps cleaned/rebuilt.

# 1.1.0 background-color addition (2026-10-22, same-version rebuild)

Added optional `backgroundColor` configuration, using Titanium's existing color conversion and `UIPopoverPresentationController.backgroundColor`. Validation/conversion runs before native presentation state is acquired; omitted/null values preserve UIKit's default. The backdrop color is applied on every show, and existing pass-through/undimmed-sheet behavior remains intact. No content-view colors or screen dimming are overridden.

Native compilation, distribution-package integrity, architecture checks, and installed-file comparison are separate from visual validation. The DateMaps developer will verify body/arrow appearance, semantic light/dark colors, material behavior, and runtime interactions. Version remains 1.1.0 at the user's request, so consumers must clean/rebuild to replace cached native binaries.

# 1.1.0 pass-through views (2026-10-22)

Added the optional `passthroughViews` configuration for native anchored presentations. Validation converts each visible ordinary Titanium proxy to its current native view before presentation ownership/lifecycle state is acquired, rejects invalid or detached entries, and assigns the resolved array to `UIPopoverPresentationController.passthroughViews`. The list is re-resolved on each show; UIKit owns native touch dispatch. Existing undimmed-sheet anchor handling is preserved.

The DateMaps developer reported `passthroughViews` working properly after installing this update. No device model, OS version, or exhaustive interaction matrix was recorded with that report. Static/native build and package verification are separate evidence; nested-sheet interactions and broader device coverage remain manual checks.

# 1.0.1 undimmed-sheet anchor fix (2026-10-22)

A native debugger inspection of the running DateMaps iOS 27.0 simulator identified the failed check as `isDescendantOfView:presenter.view` in `TiAnchoredpresentationSource`. The tapped `TiUIButton` had a window, 68 x 36 bounds, alpha 1, and no hidden/transparent ancestors. The topmost presenter was the persistent 80-point sheet at custom detent `bar`, with `largestUndimmedDetentIdentifier` set to `medium`. The source remained in the underlying drawer/navigation content, outside that sheet's view hierarchy. This is a presentation-owner conflict rather than evidence of a detached/recycled source.

The resolver now permits an underlying source only when the topmost presenter is an undimmed sheet at or below its configured undimmed detent, the source belongs to that sheet's presenting content, and the sheet does not cover the source center. Presentation still comes from the topmost sheet. The existing attachment, bounds, ancestor visibility, presenter transition/window, and other modal checks remain in place.

An isolated UIKit harness compiled the exact resolver source with minimal Titanium proxy stubs. On an iOS 27.0 simulator, all 17 checks passed: ordinary source resolution; three popover presentation/dismissal cycles from the sheet, replacing the source button between cycles; source-provider resolution while excluding the active popover; and rejection of hidden, transparent, empty, detached, sheet-covered, dimmed-sheet, and full-screen-modal-covered sources. This exercises real UIKit presentations and the resolver logic, but does not reproduce Titanium TableView recycling or prove DateMaps/device behavior after installation.

Native module builds passed for device arm64 and simulator arm64/x86_64 using Titanium SDK 13.4.1.GA and Xcode 27.1 beta. DateMaps build and physical-device verification remain separate checks.

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
