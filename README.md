# ESADesignKit

Shared look & feel for Extremely Successful Apps. A SwiftUI package that
harmonizes branding and common UI across apps.

## Install

Add the package locally (File ▸ Add Package Dependencies… ▸ Add Local), pointing
at this folder, or via its git URL. Then `import ESADesignKit`.

## Contents

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

Optional parameters: `blurRadius`, `minHeight`, `cornerRadius`,
`contentPadding`, `placeholderColor`. The struct form `ESARowView(image:) { … }`
is also available.

### `CreatedByView` — shared footer

```swift
CreatedByView(
    gitURL: URL(string: "https://github.com/holgerkrupp/PodcastClient")
)
```

`websiteURL`, `creditText`, and `showVersion` are configurable; pass
`gitURL: nil` to hide the source-code link.

### Brand symbols

```swift
Image.esaLogo          // "extremelysuccessfullogo"
Image.esaGitHubLogo    // "githublogo"
```

Names are also exposed via `ESASymbol.logo` / `ESASymbol.gitHubLogo`.
