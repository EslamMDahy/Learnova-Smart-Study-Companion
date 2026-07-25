# Third-party notices

## dom-to-pptx

- Version: 2.0.3
- License: MIT
- Bundled file: `vendor/dom-to-pptx.bundle.js`
- Upstream package: `dom-to-pptx`

Learnova includes one small compatibility patch in the bundled browser build: CSS
`direction: rtl` is forwarded to PptxGenJS as `rtlMode: true`, so Arabic text is
stored as native RTL PowerPoint text. The original MIT license is included in
`vendor/dom-to-pptx.LICENSE`.

## MathJax

- Version: 3.2.2
- License: Apache License 2.0
- Bundled file: `vendor/mathjax/tex-svg-full.js`
- License file: `vendor/mathjax/LICENSE`
- Upstream package: `mathjax-full`

MathJax is loaded locally only when a complex LaTeX equation needs SVG rendering.
