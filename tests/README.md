# Dimming geometry fixture

`dimmingGeometry.m` is an isolated UIKit simulator app linked with the production `TiAnchoredpresentationDimmingView.m`. It checks pixel alpha for background opacity, rounded cutouts, overlapping cutouts, hidden/moved/detached views, ancestor clipping, noninteractive/accessibility settings, and display-link teardown. It does not replace Titanium bridge or native transition interaction tests.

Compile with the selected Xcode's simulator clang using ARC, an iOS 26 minimum, the module's `ios/Classes` include path, and UIKit/Foundation/QuartzCore/CoreGraphics frameworks. Package the executable in an app bundle with a scene-enabled Info.plist (delegate `GeometryApp`, scene configuration supplied by the delegate), install on a test simulator, and launch with console output. A successful run logs `DIM_GEOMETRY COMPLETE failures=0` after the window's initial layout. `example/dimming.js` supplies the manual Titanium interaction fixture; `example/rapidLifecycle.js` supplies repeated native presentation coverage.

Copy `dimmingLifecycle.js` to an isolated Classic app Resources/app.js with the 1.2.1 module installed app-locally. It exercises 40 shows/dismissals while varying dimming enabled/disabled, zero opacity, exclusions, native system/zoom transitions, early hides, and action sheets. The intentionally hidden avatar is not used as a pass-through view.

The 1.2.1 geometry fixture also checks visual wrappers around inner controls, individual corners, CAShapeLayer masks, configured UIKit capsules, inscribed circles, explicit capsules/rounded rectangles, zero/clamped radii, and rounded ancestor clips. The lifecycle fixture cycles all four shape modes.
