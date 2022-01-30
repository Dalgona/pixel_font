defmodule PixelFont.Font do
  alias PixelFont.Font.Metrics
  alias PixelFont.TableSource.OS_2

  defstruct version: Version.parse!("0.0.0"),
            name_table: [],
            metrics: %Metrics{},
            os_2: %OS_2{},
            glyph_sources: [],
            gpos_lookups: [],
            gsub_lookups: []

  @type t :: %__MODULE__{
          version: Version.t(),
          name_table: [map()],
          metrics: Metrics.t(),
          os_2: OS_2.t(),
          glyph_sources: [module()],
          gpos_lookups: [module()],
          gsub_lookups: [module()]
        }

  @callback font([binary()]) :: t()
end
