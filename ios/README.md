# Native build

Build from this directory with Titanium SDK 13.4.1.GA or later. The Xcode project uses ARC and an iOS 26 deployment target. Use Xcode 26+ for the Liquid Glass APIs/appearance; the initial build was validated with Xcode 27.1 beta.

```sh
ti build -p ios --build-only --project-dir . --sdk 13.4.1.GA
```

The ZIP is written to dist/. See the parent README for the API, source rules, and examples. Installation is manual; builds do not install the module globally.
