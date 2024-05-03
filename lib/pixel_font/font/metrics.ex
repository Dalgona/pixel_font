defmodule PixelFont.Font.Metrics do
  defstruct pixels_per_em: 16,
            units_per_em: 1024,
            ascender: 0,
            descender: 0,
            line_gap: 0,
            underline_size: 1,
            underline_position: 0,
            is_fixed_pitch: false

  @type t :: %__MODULE__{
          pixels_per_em: non_neg_integer(),
          units_per_em: non_neg_integer(),
          ascender: non_neg_integer(),
          descender: non_neg_integer(),
          line_gap: non_neg_integer(),
          underline_size: non_neg_integer(),
          underline_position: integer(),
          is_fixed_pitch: boolean()
        }

  @spec scale(t(), number()) :: integer()
  def scale(%__MODULE__{} = metrics, coord) do
    round(coord * metrics.units_per_em / metrics.pixels_per_em)
  end
end
