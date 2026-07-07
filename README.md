# ESADesignKit

The shared toolkit for **Extremely Successful Apps**. A SwiftUI package that
houses the reusable pieces — branding, signature UI, and device helpers — that
every app I publish under the *Extremely Successful Apps* name uses, so the look
and feel stay consistent and nothing has to be rebuilt per app.

Think of this package as the single home for "things more than one ESA app
needs." When a component, symbol, or helper becomes reusable, it moves here.

## Why this exists

- **One source of truth for branding** — logo, footer credit, and the company
  link live in one place. Change them once, every app updates.
- **Consistent UI** — the signature list-row look is identical across apps
  because they all draw from the same view.
- **Less duplication** — device-style helpers and shared imagery are imported,
  not copy-pasted into each project.

## Requirements

- iOS 18+ / macOS 14+ / watchOS 11+
- Swift 6
- Depends on the local `DeviceInfo` package (at `../DeviceInfo`), which is
  re-exported — see [Device helpers](#device-helpers).

## Install

Add the package locally (**File ▸ Add Package Dependencies… ▸ Add Local**),
pointing at this folder, or via its git URL. Then:

```swift
import ESADesignKit
```

## What's inside

### `ESA_RowView` — the signature list-row look

A blurred, full-bleed cover image behind a `.thinMaterial` content layer. Apply
it to any row content. The image can be a `URL` (downloaded once, blurred via
Core Image, and cached — no live `.blur()` per scroll) or a SwiftUI `Image`.

```swift
HStack {
    Text(episode.title)
    Spacer()
}
.ESA_RowView(image: episode.imageURL)        // URL
// or
.ESA_RowView(image: Image("placeholder"))     // SwiftUI Image
```

The blur, dim, and content alignment are fixed so every row looks identical
across apps; only `minHeight` (and optional `cornerRadius`) vary per use site.
The struct form `ESARowView(image:minHeight:) { … }` is also available.

### `ESAFullBackground` — the signature detail-screen backdrop

A heavily blurred, dimmed cover image that fills the whole screen behind safe
areas — the look from `PodcastDetailView`. Apply it to a `List`/`ScrollView`
container; the image can be a `URL` (pre-blurred + cached) or a SwiftUI `Image`.

```swift
List {
    // …
}
.ESAFullBackground(image: podcast.imageURL)   // URL
// or
.ESAFullBackground(image: Image("cover"))      // SwiftUI Image
```

Blur radius (15) and opacity (0.5) are fixed for a consistent look. The struct
form `ESAFullBackground(image:)` is also available.

### `coverHero` — the immersive detail cover

A full-width cover drawn **behind** a detail screen's scrolling content. At rest
the whole cover is visible at its natural height; as the content scrolls up the
cover grows — pinned to the top and bleeding under the safe areas — until it
covers the full screen height, while the content slides up over it as a frosted
panel.

It's a **single modifier** on any scroll container — `List`, `ScrollView`, … —
that adapts the content automatically. `.coverHero(…)`:

1. makes the scroll content transparent,
2. reserves the cover's footprint with a scrollable top margin (no spacer view),
3. paints one continuous frosted sheet behind the content that rises over the
   cover as you scroll, and
4. draws the zooming cover behind it all.

```swift
ScrollView {
    VStack(spacing: 16) {
        // content…
    }
}
.coverHero(imageData: cover, title: name)
```

Scroll tracking uses `onScrollGeometryChange`, so the grow-on-scroll effect is
active on iOS 18 / macOS 15 / watchOS 11 and newer; older systems just show the
cover without the zoom.

#### One caveat for `List`

`.coverHero` makes the list's *background* transparent, but SwiftUI still gives
each **row cell** an opaque system background. Set your rows clear so the frosted
sheet shows through them (headers/footers are handled for you):

```swift
List {
    Section("Info") {
        // rows…
    }
    .listRowBackground(Color.clear)     // ← required so rows aren't solid white
}
.listStyle(.plain)
.coverHero(imageData: game.artwork, title: game.name)
```

`ScrollView`/`VStack` content needs nothing extra.

#### Notes

- `enabled:` gates the effect — e.g. `enabled: horizontalSizeClass == .compact`
  so a full-bleed hero shows on iPhone while a wide layout opts out (returns the
  content unchanged).
- `material:` sets the frosting (default `.ultraThinMaterial`).
- `title` is optional; pass `""` to draw the cover without a title overlay.
- Layer it over `ESAFullBackground` for a blurred backdrop behind the frosted
  content and in any letterboxed areas.

#### Advanced: hand-built frosting

For layouts that need finer control than the automatic sheet, the building
blocks are also public: `frostedDetailRow()` / `frostedDetailSectionHeader()`
(per-cell `List` frosting), `frostedContentPanel(coverImageData:)` (one-shot
frosting + spacer for non-`List` content), and `CoverHeroSpacer` (a manual
footprint spacer). Most callers won't need these — `.coverHero` alone is enough.

### `CreatedByView` — shared footer

The "Created in Buxtehude by Extremely Successful Apps" credit footer, ready to
drop into any app's About or settings screen.

```swift
CreatedByView(
    gitURL: URL(string: "https://github.com/holgerkrupp/PodcastClient")
)
```

`creditText`, `websiteURL`, and `showVersion` are configurable; pass
`gitURL: nil` to hide the source-code link.

### Brand symbols

The shared logos, so apps reference them by name instead of bundling their own.

```swift
Image.esaLogo          // "extremelysuccessfullogo"
Image.esaGitHubLogo    // "githublogo"
```

The raw names are also exposed via `ESASymbol.logo` / `ESASymbol.gitHubLogo`
for callers that want to build the `Image`/`Label` themselves.

### Device helpers

ESADesignKit owns the `DeviceInfo` dependency and re-exports it, so importing
ESADesignKit gives you DeviceInfo's helpers (`\.deviceUIStyle`,
`.withDeviceStyle()`, `DeviceUIStyle`, `DeviceDetector`) without your app
referencing the DeviceInfo package directly.

## Adding new reusable items

When something becomes shared across apps:

1. Add it to `Sources/ESADesignKit/` (assets go in
   `Resources/ESAAssets.xcassets`).
2. Mark the public API `public`.
3. Document it here under [What's inside](#whats-inside).
4. Add a test in `Tests/ESADesignKitTests/` where it makes sense.
