# CustomMenu assessment — 2026-10-07

Reviewed the supplied `CustomMenu` project. The supplied project builds for iOS Simulator with Xcode 27.1 beta. This review establishes source/API usage and compilation, not runtime visual parity or gesture behavior.

## Existing module cleanup

The maintained Classic, Alloy, and lifecycle examples no longer force `arrowDirections: 0`. The native proxy defaults to `UIPopoverArrowDirectionAny`; the source resolver preserves existing toolbar/navigation UIBarButtonItems. There is no arrowless animator, custom background, or SwiftUI implementation to remove. Retain the controller-specific lifecycle guards from 0.1.1: these prevent stale dismissal callbacks from clearing reopened content and do not supply animation. The arrow cleanup itself needs no animator changes. The zoom addition is included in the user-requested same-version 0.1.1 rebuild.

## What CustomMenu does

`CustomMenuView.swift` wraps the source label in a SwiftUI Button, applies `.glass` or `.glassProminent`, marks the label with `matchedTransitionSource`, presents custom content using `.popover`, and explicitly requests `.navigationTransition(.zoom(...))`. It does not set arrow directions to zero. Its helper keeps popover adaptation on compact layouts. A separate helper delays content visibility by 100 ms and fades it in over 300 ms; this is custom content timing, not the source of the system zoom transition.

The example demonstrates a glass-styled Button containing a calendar icon. It does not demonstrate every arbitrary View/ImageView morphing identically.

## UIKit implementation

Implemented opt-in `transition: 'zoom'` on custom-content popovers, retaining `'system'` as the default. Source-view and iOS 26 bar-button-item providers are configured through UIKit's preferredTransition. No SwiftUI dependency or custom animator was added.

The module now targets iOS 26+ only. UIKit exposes `UIViewController.preferredTransition` and `UIViewControllerTransition`'s zoom source-view provider from iOS 18; its source-bar-button-item provider is available from iOS 26. Request the preferred transition on the presented Titanium content controller and return the actual visible source UIView from a weak provider. Preserve the existing sourceItem/sourceRect anchor and let UIKit choose its arrow and chrome. No SwiftUI host, replacement animator, or guessed content-fade delay is needed for the first proof of concept.

UIKit explicitly documents this as a preference that may be ignored in unsupported contexts. First verify zoom on popovers from a normal button, avatar View/ImageView, and glass-styled control; compare with the supplied SwiftUI example. Test interactive dismissal/cancellation, source removal/recycling, repeated opening, outside dismissal, and content resizing on iOS 26/27 and iPad. If the context ignores zoom, report the limitation instead of silently replacing the presentation with a custom animator or full-screen zoom.

The sample is a useful design reference and a promising native API direction. Compilation alone does not prove that a UIKit popover will reproduce SwiftUI's precise glass morph.
