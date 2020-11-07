defmodule PixelFont.TableSource.Hmtx.Record do
  alias PixelFont.Glyph
  alias PixelFont.Glyph.{BitmapData, CompositeData}

  defstruct ~w(advance lsb xmin xmax glyph_empty?)a

  @type t :: %__MODULE__{
          advance: pos_integer(),
          lsb: integer(),
          xmin: non_neg_integer(),
          xmax: non_neg_integer(),
          glyph_empty?: boolean()
        }

  @spec new(Glyph.t()) :: t()
  def new(glyph)

  def new(%Glyph{data: %BitmapData{} = data}) do
    %__MODULE__{
      advance: data.advance,
      lsb: data.xmin,
      xmin: data.xmin,
      xmax: data.xmax,
      glyph_empty?: Enum.empty?(data.contours)
    }
  end

  def new(%Glyph{data: %CompositeData{} = data}) do
    case Enum.find(data.components, &(:use_my_metrics in &1.flags)) do
      nil -> calculate_metrics_from_components(data.components)
      %{glyph: glyph} -> new(glyph)
    end
  end

  @spec calculate_metrics_from_components([CompositeData.glyph_component()]) :: t()
  defp calculate_metrics_from_components(components) do
    metrics =
      Enum.map(components, fn %{glyph: %Glyph{data: %BitmapData{} = data}, x_offset: xoff} ->
        %{
          advance: data.advance + xoff,
          xmin: data.xmin + xoff,
          xmax: data.xmax + xoff
        }
      end)

    advance = metrics |> Enum.map(& &1.advance) |> Enum.max(fn -> 0 end)
    xmin = metrics |> Enum.map(& &1.xmin) |> Enum.min(fn -> 0 end)
    xmax = metrics |> Enum.map(& &1.xmax) |> Enum.max(fn -> 0 end)

    %__MODULE__{
      advance: advance,
      lsb: xmin,
      xmin: xmin,
      xmax: xmax,
      glyph_empty?: Enum.empty?(components)
    }
  end

  @spec compile(t()) :: iodata()
  def compile(record) do
    [
      <<record.advance::big-16>>,
      <<record.lsb::big-16>>
    ]
  end
end
