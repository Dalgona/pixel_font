defmodule PixelFont.TableSource.Glyf.Item do
  alias PixelFont.Font.Metrics
  alias PixelFont.Glyph
  alias PixelFont.Glyph.{BitmapData, CompositeData}
  alias PixelFont.TableSource.Glyf.Simple
  alias PixelFont.TableSource.Glyf.Composite
  import Metrics, only: [scale: 2]

  defstruct ~w(num_of_contours xmin ymin xmax ymax description)a

  @type t :: %__MODULE__{
          num_of_contours: integer(),
          xmin: integer(),
          ymin: integer(),
          xmax: integer(),
          ymax: integer(),
          description: Simple.t() | Composite.t()
        }

  @spec new(Glyph.t(), Metrics.t()) :: t()
  def new(glyph, metrics)

  def new(%Glyph{data: %BitmapData{} = data}, %Metrics{} = metrics) do
    %__MODULE__{
      num_of_contours: length(data.contours),
      xmin: scale(metrics, data.xmin),
      ymin: scale(metrics, data.ymin),
      xmax: scale(metrics, data.xmax),
      ymax: scale(metrics, data.ymax),
      description: Simple.new(data.contours, metrics)
    }
  end

  @spec new(Glyph.t(), Metrics.t()) :: t()
  def new(%Glyph{data: %CompositeData{} = data}, %Metrics{} = metrics) do
    boundaries =
      data.components
      |> Enum.map(fn %{glyph: %Glyph{} = ref_glyph, x_offset: xoff, y_offset: yoff} ->
        %BitmapData{xmin: xmin, ymin: ymin, xmax: xmax, ymax: ymax} = ref_glyph.data

        {xmin + xoff, ymin + yoff, xmax + xoff, ymax + yoff}
      end)

    zero = fn -> 0 end

    %__MODULE__{
      num_of_contours: -1,
      xmin: scale(metrics, boundaries |> Enum.map(&elem(&1, 0)) |> Enum.min(zero)),
      ymin: scale(metrics, boundaries |> Enum.map(&elem(&1, 1)) |> Enum.min(zero)),
      xmax: scale(metrics, boundaries |> Enum.map(&elem(&1, 2)) |> Enum.max(zero)),
      ymax: scale(metrics, boundaries |> Enum.map(&elem(&1, 3)) |> Enum.max(zero)),
      description: Composite.new(data.components, metrics)
    }
  end

  @spec compile(t()) :: map()
  def compile(item)

  def compile(%{num_of_contours: 0}) do
    %{
      data: "",
      real_size: 0,
      padded_size: 0
    }
  end

  def compile(item) do
    data = [
      <<item.num_of_contours::big-16>>,
      <<item.xmin::big-16>>,
      <<item.ymin::big-16>>,
      <<item.xmax::big-16>>,
      <<item.ymax::big-16>>,
      compile_description(item.description)
    ]

    data_bin = IO.iodata_to_binary(data)
    size = byte_size(data_bin)

    pad_size =
      case rem(size, 4) do
        0 -> 0
        x -> 4 - x
      end

    pad = <<0::pad_size*8>>

    %{
      data: data_bin <> pad,
      real_size: size,
      padded_size: size + pad_size
    }
  end

  defp compile_description(desc)

  defp compile_description(%Simple{} = desc) do
    %Simple{inst_size: inst_size} = desc

    [
      Enum.map(desc.last_points, &<<&1::big-16>>),
      <<inst_size::big-16>>,
      desc.inst,
      desc.flags,
      desc.x_coords,
      desc.y_coords
    ]
  end

  defp compile_description(%Composite{} = desc) do
    desc.components
  end
end
