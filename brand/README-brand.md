# PatternIQ brand files

Rendered at 2x, so every file is twice its nominal size in pixels and stays crisp on retina displays.

| File | Nominal | Actual pixels | Use |
|---|---|---|---|
| `patterniq-card-1200x630.png` | 1200 x 630 | 2400 x 1260 | **Kajabi search page image, social share, Open Graph.** The standard preview size. |
| `patterniq-card-1280x720.png` | 1280 x 720 | 2560 x 1440 | 16:9 product or course thumbnail |
| `patterniq-mark-1024.png` | 1024 x 1024 | 2048 x 2048 | Square avatar, app icon, profile image |
| `patterniq-horizontal-1600x400.png` | 1600 x 400 | 3200 x 800 | Header, email banner, wide lockup |
| `_artboards-source.html` | | | Editable source. Open in a browser and screenshot any artboard to re-render. |

If Kajabi rejects a file for size, the 1200 x 630 is the one to use.

## The mark

A gold signal line rising through faint, irregular candles. The candles are the noise, the line is the pattern. It is the product thesis in one image: a clean reading extracted from messy data, with the underlying data still visible rather than hidden.

The candles are deliberately uneven. A tidy ascending series would say something the product does not believe.

## Colors

| Token | Hex | Use |
|---|---|---|
| Ground | `#0A0E14` | Background |
| Panel | `#0E1620` | Mark interior |
| Border | `#233042` | Mark edge, grid |
| Gold | `#E0A93C` | Signal line, "IQ", rule, top edge |
| Text | `#EDF3F8` | "Pattern" |
| Dim | `#9BAFC4` | Tagline |
| Faint | `#6F8496` | Byline |

Gold on ground measures 9.1:1, well past AAA. The tagline measures 7.9:1. Both readable at thumbnail size.

## Type

Plus Jakarta Sans, embedded directly in the source file as base64 so it renders identically anywhere, with no network request and no font substitution. Wordmark is 800 weight at minus 0.035em tracking; tagline is 400.

## Tagline

"Show the evidence. Quantify the uncertainty." Two of the six obligations from the product's governing sentence. It promises method rather than returns, which is both accurate and the reason it is safe to put in front of an investor.

## Editing

Open `_artboards-source.html` in a browser. Each artboard is a `div` with an id (`c1200`, `c1280`, `m1024`, `h1600`). Change the copy or colors in the CSS at the top, then screenshot the element. No design tool required.
