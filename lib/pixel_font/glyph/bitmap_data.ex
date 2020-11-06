defmodule PixelFont.Glyph.BitmapData do
  alias PixelFont.RectilinearShape.Path

  defstruct advance: 0,
            xmin: 0,
            xmax: 0,
            ymin: 0,
            ymax: 0,
            data: "",
            contours: []

  @type t :: %__MODULE__{
          advance: integer(),
          xmin: non_neg_integer(),
          xmax: non_neg_integer(),
          ymin: non_neg_integer(),
          ymax: non_neg_integer(),
          data: binary(),
          contours: Path.t()
        }
end
