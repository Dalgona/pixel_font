defmodule PixelFont.GlyphStorage do
  alias PixelFont.Glyph

  @module Application.compile_env(:pixel_font, :glyph_storage, __MODULE__.GenServer)

  @callback all() :: [Glyph.t()]
  @callback get(id :: Glyph.id()) :: Glyph.t() | nil

  @spec all() :: [Glyph.t()]
  defdelegate all, to: @module

  @spec get(Glyph.id()) :: Glyph.t() | nil
  defdelegate get(id), to: @module
end
