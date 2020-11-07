defmodule PixelFont.TableSource.Glyf do
  alias PixelFont.CompiledTable
  alias PixelFont.GlyphStorage
  alias PixelFont.TableSource.Glyf.Item

  defstruct ~w(items)a

  @type t :: %__MODULE__{items: [Item.t()]}

  @spec generate() :: t()
  def generate do
    %__MODULE__{items: Enum.map(GlyphStorage.all(), &Item.new/1)}
  end

  @spec compile(t()) :: [CompiledTable.t()]
  def compile(glyf) do
    {pos, offsets, data} =
      glyf.items
      |> Enum.map(&Item.compile/1)
      |> Enum.reduce({0, [], []}, fn item, {pos, offsets, data} ->
        {pos + item.padded_size, [pos | offsets], [item.data | data]}
      end)

    loca_data =
      [pos | offsets]
      |> Enum.reverse()
      |> Enum.map(&<<&1::big-32>>)
      |> IO.iodata_to_binary()

    glyf_data =
      data
      |> Enum.reverse()
      |> IO.iodata_to_binary()

    [
      CompiledTable.new("loca", loca_data),
      CompiledTable.new("glyf", glyf_data)
    ]
  end
end
