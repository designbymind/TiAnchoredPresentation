Copy controllers/, views/, and styles/ into a new iOS Alloy app. Add ti.anchoredpresentation 1.0.0 to tiapp.xml and set the minimum iOS version to 26+. The custom content lives in a separate controller and uses Backbone events for resize/close requests.

Try the navigation buttons, toolbar button, normal button, and card. Dismiss by tapping outside and by using Close. Reopen and resize repeatedly. Test both iPhone and iPad on iOS 26/27; exact animation and accessibility behavior need runtime validation.

The popover requests `transition: 'zoom'`. Remove that property to compare UIKit's default. Install 1.0.0 and update the app module version.
