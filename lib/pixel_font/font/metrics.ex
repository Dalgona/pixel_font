defmodule PixelFont.Font.Metrics do
  defstruct units_per_em: 0,
            ascender: 0,
            descender: 0,
            line_gap: 0,
            underline_size: 1,
            underline_position: 0,
            is_fixed_pitch: false

  @type t :: %__MODULE__{
          units_per_em: non_neg_integer(),
          ascender: non_neg_integer(),
          descender: non_neg_integer(),
          line_gap: non_neg_integer(),
          underline_size: non_neg_integer(),
          underline_position: integer(),
          is_fixed_pitch: boolean()
        }
end
