defmodule PixelFont.Glyph do
  alias PixelFont.Glyph.BitmapData
  alias PixelFont.Glyph.CompositeData
  alias PixelFont.Glyph.VariationSequence

  defstruct id: 0, gid: 0, data: %BitmapData{}, variations: false

  @type t :: %__MODULE__{
          id: id(),
          gid: non_neg_integer(),
          data: data(),
          variations: VariationSequence.t() | false
        }

  @type id :: non_neg_integer() | binary()
  @type data :: BitmapData.t() | CompositeData.t()
end
