# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

`clipboard-controller` is a macOS menu bar application. It does two things at
once, because both read the same event, a change of the clipboard:

1. **A clipboard history.** It stores what you copy: text, formatted text, links
   and images. The menu gives every clip back.
2. **A clipboard cleaner.** It removes the formatting of the text you copy, and
   it removes the invisible characters and the tracking parameters of a URL.

The application is an agent application (`LSUIElement: true`). It has no dock
icon and no ordinary windows. It is not sandboxed, because the history and the
cleaner need the whole clipboard.

The application never presses Command+V for you. It writes the clip to the
clipboard, and you paste. That is why it needs **no Accessibility permission**.

## Commands

```bash
make build       # build the Release app into ./build
make debug       # build the Debug app into ./build
make test        # run the unit tests
make run         # build, then launch the app
make install     # copy the app into /Applications
make dmg         # build the Release app and pack it into ./dist/*.dmg
make generate    # rebuild ClipboardController.xcodeproj from project.yml (needs xcodegen)
make clean       # remove ./build and ./dist
```

To run one test suite or one test:

```bash
xcodebuild -project ClipboardController.xcodeproj -scheme ClipboardController \
  -configuration Debug -destination 'platform=macOS,arch=arm64' \
  -parallel-testing-enabled NO \
  -only-testing:ClipboardControllerTests/Sanitizer test
```

Add the test function name for one test, for example
`-only-testing:ClipboardControllerTests/Sanitizer/removesUTM`.

Parallel testing must stay off. The test bundle loads into the real application,
so a parallel run launches one copy of the application for each test worker.

## Icons

The application icon and the menu bar icon are the same Tabler `clipboard`
outline at stroke width 2. The path exists twice, because the icon script runs
outside the application and cannot import its code: in
`Sources/ClipboardController/Views/ClipboardGlyph.swift` and in
`Tools/make-icon.swift`. Change the two together.

The corners come from the tangent arc, `appendArc(from:to:radius:)` in AppKit and
`addArc(tangent1End:tangent2End:radius:)` in Core Graphics. It draws the same
shape as the `a 2 2 0 0 0` command of the SVG, and it needs no angle, so a
flipped y axis changes nothing.

The application icon is an Icon Composer document, `Resources/AppIcon.icon`:

| File | What it is |
| --- | --- |
| `icon.json` | Written by hand. It holds the colours of the two appearances. |
| `Assets/clipboard.svg` | Written by `Tools/make-icon.swift`. |
| `Docs/icon-light.png`, `Docs/icon-dark.png` | The previews for the README. |

Run `swift Tools/make-icon.swift` after any change of the path. The script turns
the stroke into a filled outline, because a layer of a `.icon` is filled and Icon
Composer colours it per appearance.

`actool` builds two things from the document: an icon group with the `Aqua` and
`DarkAqua` appearances for macOS 26, and `AppIcon.icns` for macOS 15, which has
no dark application icons. The light drawing is the fallback.

`project.yml` needs `options.fileTypes.icon.file: true`. Without it XcodeGen
adds the files inside the document one by one and the icon never reaches
`actool`.

## Releases

`.github/workflows/release.yml` publishes a release. A tag that starts with `v`
starts it:

```bash
git tag -a v1.0.0 -m "v1.0.0"
git push origin v1.0.0
```

The workflow runs the tests, calls `make dmg`, and attaches the disk image to a
new GitHub release. It passes the version of the tag as `MARKETING_VERSION` and
the run number as `CURRENT_PROJECT_VERSION`, so `project.yml` does not need a
change for each release.

The last step then writes the version into `project.yml` and into
`ClipboardController.xcodeproj/project.pbxproj`, so a local build shows the
version of the last release. Do not edit the `MARKETING_VERSION` lines by hand.

The application is signed ad hoc. There is no Apple Developer ID and no
notarization, so macOS blocks the first launch. The release notes and the README
explain the two ways to open it.

## Homebrew

This repository is also the Homebrew tap. The cask is
`Casks/clipboard-controller.rb`. A tap needs only a `Casks/` directory at its
root, so no second repository exists. The name of the repository has no
`homebrew-` prefix, so the tap command needs the URL:

```bash
brew tap fballiano/clipboard-controller https://github.com/fballiano/clipboard-controller
brew trust --cask fballiano/clipboard-controller/clipboard-controller
brew install --cask clipboard-controller
```

Homebrew 6 refuses to load a cask from a tap outside `Homebrew/*` until the user
trusts it, so `brew trust` is part of the instructions.

The same last step of the workflow writes the new `version` and `sha256` into the
cask and pushes the change to the default branch. Do not edit the two lines by
hand.

## Project file

`ClipboardController.xcodeproj` is generated from `project.yml` by XcodeGen, but
it is committed. Change `project.yml` and run `make generate` for any change of
the project layout: a new package, a new target, a build setting, or an
`Info.plist` key. Do not edit `project.pbxproj` by hand.

The `Info.plist` at `Support/Info.plist` also receives keys from `project.yml`.

## Architecture

`AppModel` is the one controller, a `@MainActor @Observable` singleton
(`AppModel.shared`). Every way into the application calls the same method on it:

| Entry point | File |
| --- | --- |
| Menu | `Views/MenuBarController.swift` |
| History window | `Views/HistoryView.swift` |
| Global hot key | `HotKeys.swift`, wired in `AppModel.registerHotKeys()` |
| AppleScript | `Scripting/ScriptCommands.swift` with `Resources/clipboard-controller.sdef` |
| Shortcuts and Spotlight | `Scripting/ClipboardIntents.swift` |

Keep this rule. A new command needs one method on `AppModel`, then a call from
each entry point. Do not put logic in a view, a script command or an intent.

AppKit builds the menu, not SwiftUI. `MenuBarController` owns the `NSStatusItem`
and the `NSMenu`, and `menuNeedsUpdate` writes the items again at each opening.
The reason is the picture of an image clip: SwiftUI draws the icon of a menu row
at the height of the text, and no value changes that, while an `NSMenuItem` keeps
the size of its image and makes its row taller. `ClipboardControllerApp` is
therefore an AppKit `main`, not a SwiftUI `App`. SwiftUI still draws the windows.

Private mode is the first item of the menu, in its own group. A user reaches for
it when something private is about to go on the clipboard, so it must be the item
under the pointer. Do not move it down the list.

### The path of one copy

```
NSPasteboard  →  ClipboardMonitor  →  Sanitizer  →  NSPasteboard (the clean text)
                        ↓
                 ClipboardContent  →  AppModel.record  →  ClipStore  →  Clip
```

`ClipboardMonitor` polls `changeCount` four times a second. macOS sends no
notification for a change of the clipboard, so a poll is the only way. The timer
runs in `RunLoop.Mode.common`, so it keeps working while the menu is open.

The monitor never reads `Preferences`. It calls a closure that returns a
`ClipboardPolicy`, a copy of the settings. A test can therefore give any
combination of settings without a `UserDefaults` instance.

The monitor stores the `changeCount` of its own write, so the cleaner does not
read its own result and clean it a second time. `AppModel.copy(_:)` calls
`ignoreCurrentContent()` for the same reason.

### Privacy rules

These rules are not options. Do not add a setting that turns them off:

- A clipboard that carries `org.nspasteboard.ConcealedType` or
  `com.agilebits.onepassword` is a password. The app does not read it, does not
  clean it and does not store it.
- A clipboard that carries `org.nspasteboard.TransientType` or
  `org.nspasteboard.AutoGeneratedType` belongs to another tool. The app skips it.
- The cleaner never touches a clipboard that holds a file, and never touches a
  picture.

`PasteboardMarker` in `Pasteboard.swift` holds the four types.

### The cleaner

`Sanitizer` is a pure `struct`: no state, no system, no AppKit. Every rule of the
text cleaner lives there, so a test reads a rule without a clipboard. The order
of the rules matters and the file says why.

`TrackingParameters` holds two tables. A name in the global table is a tracker
everywhere. A short name like `s` or `ref` is a search term on most sites, so it
lives in a host rule and never in the global table.

`InvisibleCharacters` removes the zero width characters, the bidirectional marks
and the Unicode tags block, `U+E0000` to `U+E007F`, which is where a text
generator hides a watermark. The zero width joiner, `U+200D`, needs the extra
test: it joins the parts of an emoji, so a blind removal breaks a family emoji
into three people.

### Storage

`ClipStore` holds the SwiftData container and does every read, write, prune and
export. The store gets its own folder,
`~/Library/Application Support/clipboard-controller/`, because the SwiftData
default is shared with every other application of the user.

A second copy of the same content does not add a second row: `add` finds the row
by `contentHash` and moves it to the top. A prune never deletes a pinned clip.

`AppModel` keeps a plain `[Clip]` array for the menu and calls `reloadClips()`
after each change.

`Preferences` wraps `UserDefaults`. Each property writes back in its `didSet`.
`maxStoredClips`, `maxClipAgeDays` and `menuClipCount` use a private backing
property, because an assignment to an `@Observable` property inside its own
`didSet` recurses until the stack overflows.

### Test host

The tests load into the real application, so the application launches during a
test run. `RuntimeEnvironment.isRunningTests` guards the side effects:

- `AppModel.bootstrap()` does nothing, so no hot keys, no clipboard watcher and
  no system events.
- `ClipStore` uses an in-memory container, so the live database is safe.
- `LoginItem` does not call `SMAppService`.

The app starts at login by default. `AppModel.applyDefaultLoginItem()` registers
the login item at the first launch and writes
`Preferences.appliedDefaultLoginItem`. Never register it without that flag: the
app would switch the setting back on at every launch, and a user who turned it
off could never keep it off.

Add the same guard to any new code that touches the system or the user data.

### Injection for tests

`ClipboardMonitor(pasteboard:policy:source:onCapture:)` takes the clipboard, the
settings and the front application. `Tests/…/FakePasteboard.swift` is the
clipboard that lives in memory. A test must never touch the real clipboard: the
user keeps copying while the tests run.

`ClipStore.makeContainer(inMemory: true)` gives a throw-away store.
`Preferences(defaults:)` takes a `UserDefaults` instance.
`AppModel(store:preferences:pasteboard:)` takes all three.

## Conventions

- Swift 6 with `SWIFT_STRICT_CONCURRENCY: complete`. Almost every type is
  `@MainActor`. Callbacks from AppKit and from `KeyboardShortcuts` use
  `MainActor.assumeIsolated`.
- Tests use Swift Testing (`@Suite`, `@Test`, `#expect`), not XCTest. Bind a
  value to a local constant before a `#expect` that compares a `TimeInterval`
  with a literal: inside the macro a bare literal becomes an `Int`.
- Comments explain why, not what.
- The bundle identifier is `com.fabrizioballiano.clipboard-controller`. The
  product name is `clipboard-controller`. The module name is
  `ClipboardController`.
