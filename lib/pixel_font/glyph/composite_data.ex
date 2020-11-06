defmodule PixelFont.Glyph.CompositeData do
  alias PixelFont.Glyph

  defstruct components: []

  @type t :: %__MODULE__{components: [glyph_component()]}

  @type glyph_component :: %{
          glyph_id: Glyph.id(),
          glyph: Glyph.t() | nil,
          x_offset: integer(),
          y_offset: integer(),
          flags: [flag()]
        }

  @type flag :: :use_my_metrics
end
