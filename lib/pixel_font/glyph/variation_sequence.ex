defmodule PixelFont.Glyph.VariationSequence do
  alias PixelFont.Glyph

  defstruct default: 1, non_default: %{}

  @type t :: %__MODULE__{
          default: selector_number(),
          non_default: %{optional(selector_number()) => Glyph.id()}
        }

  @type selector_number :: 1..256
end
