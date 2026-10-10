# Cancelled zoom investigation — 2026-10-07

The supplied recording shows a custom-content bubble returning after an interactive dismissal attempt, with its originating avatar/button visible beneath the glass. The user confirmed the gesture is dragging the bubble. The recording's exact device and iOS version are still needed.

Apple describes glass presentation morphs as preserving visual continuity, but the public zoom/presentation documentation does not explicitly guarantee that an ordinary source UIView stays concealed throughout every completed or cancelled popover context. Related developer reports are not proof of this exact case.

Diagnostic Titanium traces on the iOS 27.0 simulator returned the same non-nil UIView at presentation and native gesture callbacks (hidden=false, alpha=1). Thus the proposed explanation that the provider loses a UIKit-hidden source has not been established. UIView.hidden/alpha alone do not prove the source's rendered appearance; UIKit can conceal it through transition rendering.

A standalone scene-based Swift UIKit probe, with no Titanium, compares sourceItem versus sourceView/sourceRect anchoring and uses preferredTransition.zoom with a stable UIView provider. It logged cancelled=true for native interaction completions, and some snapshots showed the source concealed. Other automated drags did not begin dismissal or fully dismissed it; no matched, repeatable reproduction of the recording's settled visual defect has been established. An additional test-only attempt to cancel active native pan recognizers did not establish a reliable cancellation path. Do not treat these observations as a categorical source-visibility contract or as proof that the module is fixed.

The temporary sourceView-anchor prototype did not establish a visual correction and was removed from module source, along with diagnostic logging. Version 0.1.2 subsequently shipped manual scroll-inset control; it did not include a cancelled-zoom visibility correction.

Next: reproduce a sufficiently progressed, then cancelled drag on the recording's device/OS, inspect the settled state after the native cancellation completion, and compare with the standalone UIKit probe before choosing a correction. Do not mask the issue with manual source alpha/hidden changes or assert that all glass/zoom presentations have identical source-visibility behavior.
