defmodule PixelFont.Font do
  alias PixelFont.Font.Metrics
  alias PixelFont.TableSource.{GPOS, GSUB, OS_2}

  defstruct version: Version.parse!("0.0.0"),
            name_table: [],
            metrics: %Metrics{},
            os_2: %OS_2{},
            glyph_sources: [],
            notdef_glyph: nil,
            gpos: %GPOS{},
            gsub: %GSUB{}

  @type t :: %__MODULE__{
          version: Version.t(),
          name_table: [map()],
          metrics: Metrics.t(),
          os_2: OS_2.t(),
          glyph_sources: [module()],
          notdef_glyph: module() | nil,
          gpos: GPOS.t(),
          gsub: GSUB.t()
        }
end
