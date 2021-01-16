[
  inputs: ["mix.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [
    locals_without_parens: [
      # From the Glyph Source DSL (PixelFont.GlyphSource)
      export_glyphs: 1,
      bmp_glyph: 2,
      composite_glyph: 2,
      component: 3,
      component: 4,
      advance: 1,
      bounds: 2,
      data: 1,

      # From the Name Table DSL (PixelFont.NameTable)
      name_table: 2,
      name_records: 2,
      copyright: 1,
      family: 1,
      subfamily: 1,
      unique_id: 1,
      full_name: 1,
      version: 1,
      postscript_name: 1,
      trademark: 1,
      manufacturer: 1,
      designer: 1,
      description: 1,
      vendor_url: 1,
      designer_url: 1,
      license: 1,
      license_url: 1,
      typographic_family: 1,
      typographic_subfamily: 1,
      sample_text: 1,
      postscript_cid_findfont_name: 1,
      font_specific_name: 2,

      # From the OTF Layout DSL (PixelFont.OTFLayout)
      feature: 2,
      substitute: 2,
      backtrack: 1,
      input: 1,
      input: 2,
      lookahead: 1
    ]
  ]
]
