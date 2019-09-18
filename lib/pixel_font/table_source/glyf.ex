defmodule PixelFont.TableSource.Glyf do
  alias PixelFont.CompiledTable
  alias PixelFont.GlyphStorage
  alias PixelFont.TableSource.Glyf.Item

  defstruct ~w(items)a

  @type t :: %__MODULE__{items: [Item.t()]}

  @spec compile() :: [CompiledTable.t()]
  def compile do
    glyphs = GlyphStorage.all()

    items =
      glyphs
      |> Enum.map(fn
        %{contours: _} = simple_glyph ->
          Item.new_simple(simple_glyph)

        %{components: _} = composite_glyph ->
          Item.new_composite(composite_glyph)
      end)
      |> Enum.map(&Item.compile/1)

    {pos, offsets, data} =
      Enum.reduce(items, {0, [], []}, fn item, {pos, offsets, data} ->
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
