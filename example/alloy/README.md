Copy controllers/, views/, and styles/ into a new iOS Alloy app. Add ti.anchoredpresentation 1.2.1 to tiapp.xml and set the minimum iOS version to 26+. The custom content lives in a separate controller and uses Backbone events for resize/close requests.

Try the navigation buttons, toolbar button, normal button, and card. Dismiss by tapping outside and by using Close. Reopen and resize repeatedly. Test both iPhone and iPad on iOS 26/27; exact animation and accessibility behavior need runtime validation.

The popover requests `transition: 'zoom'`. Remove that property to compare UIKit's default. Install 1.2.1 and update the app module version.

The popover also sets `backgroundColor` for its native backdrop. The avatar example sets `passthroughViews: [$.avatar]`, allowing that avatar to receive taps while the popover is visible; the normal-button example clears the list. Both options are read at show time. See the main README for supported views and UIKit rendering behavior.

The popover enables optional screen dimming. The avatar example passes through the avatar and keeps its bounds clear; the normal-button example dims the full background. Set `dimmingEnabled: false` to compare UIKit without the extra dimming layer.

Version 1.2.1 automatically detects rounded Titanium wrappers; the avatar example additionally demonstrates an explicit circle in `dimmingCutoutShapes`. Clear overrides when changing `passthroughViews`.
