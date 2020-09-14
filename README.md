# PixelFont

"PixelFont" is an all-in-one tool for creating TrueType outline fonts from bitmap glyph data.

"PixelFont" implements a subset of the [OpenType specification](https://docs.microsoft.com/en-us/typography/opentype/spec/), purely in [Elixir](https://elixir-lang.org) programming language.

## Features

- Builds full-featured font files which can be used in serious places.
- Generates optimal pixelated TrueType outlines based on 1bpp bitmap images.
- Supports creating fonts with OpenType advanced typographic features, namely GPOS and GSUB.
- Provides DSL and data structures for defining...
  - Font metadata,
  - TrueType outline glyphs based on bitmap image,
  - Composite glyphs (maximum depth of 1 for now),
  - And a subset of GPOS and GSUB lookups.

If you are in doubt, see [The NeoDunggeunmo Project](https://github.com/Dalgona/neodgm).

## Future Goals

- Write some documentations and tests.
- Implement more GPOS and GSUB lookup subtables.
- Wrap all the struct craziness with Elixir DSL. Specifically, provide user experience somewhat similar to using GUI-based font development software... via Elixir DSL. (Good luck!)

## License

Copyright 2020 Eunbin Jeong (Dalgona.) &lt;me@dalgona.dev&gt;

This software is not yet released for general availability, and it shall be used only for building font projects I am working on, just for now. Once this project is mature enough, it will be released under the MIT license.

_OpenType is a registered trademark of Microsoft Corporation._

_TrueType is a trademark of Apple Inc., registered in the United States and other countries._
