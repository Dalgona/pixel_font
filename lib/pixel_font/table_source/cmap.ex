defmodule PixelFont.TableSource.Cmap do
  require PixelFont.Util, as: Util
  import Util, only: :macros
  alias PixelFont.CompiledTable
  alias PixelFont.GlyphStorage
  alias PixelFont.TableSource.Name.Definitions, as: Defs

  @spec compile() :: CompiledTable.t()
  def compile do
    all_glyphs = GlyphStorage.all()

    {encoding_record, encoding_subtable} = compile_encoding_subtable(all_glyphs, 12)

    data = [
      # 'cmap' table version
      <<0::16>>,
      # Number of subtable(s)
      <<1::16>>,
      # Subtable records
      [encoding_record],
      # Subtables
      [encoding_subtable]
    ]

    CompiledTable.new("cmap", IO.iodata_to_binary(data))
  end

  defp compile_encoding_subtable(all_glyphs, offset) do
    unicode_ranges = get_unicode_ranges(all_glyphs)
    seg_count = length(unicode_ranges) + 1
    subtable_size = 16 + seg_count * 8
    platform_id = Defs.platform_id(:windows)
    encoding_id = Defs.encoding_id(:windows, :unicode_bmp)

    subtable_record = <<platform_id::16, encoding_id::16, offset::32>>

    subtable =
      IO.iodata_to_binary([
        # Subtable format 4: Segment mapping to delta values
        <<4::16>>,
        <<subtable_size::16>>,
        <<0::16>>,
        lookup_fields(seg_count),
        cmap_data(unicode_ranges),
        <<0::seg_count*16>>
      ])

    {subtable_record, subtable}
  end

  defp lookup_fields(seg_count) do
    search_range = trunc(2 * :math.pow(2, trunc(:math.log2(seg_count))))
    entry_selector = search_range |> div(2) |> :math.log2() |> trunc()
    range_shift = 2 * seg_count - search_range

    [<<2 * seg_count::16>>, <<search_range::16>>, <<entry_selector::16>>, <<range_shift::16>>]
  end

  defp cmap_data(ranges) do
    {start_codes, end_codes} = ranges |> Enum.map(&{&1.first, &1.last}) |> Enum.unzip()
    id_deltas = Enum.map(start_codes, &(gid!(&1) - &1))

    [
      Enum.map(end_codes, &<<&1::16>>),
      <<0xFFFF::16>>,
      <<0::16>>,
      Enum.map(start_codes, &<<&1::16>>),
      <<0xFFFF::16>>,
      Enum.map(id_deltas, &<<&1::16>>),
      <<1::16>>
    ]
  end

  defp get_unicode_ranges(all_glyphs) do
    [c | cs] =
      all_glyphs
      |> Enum.filter(&is_integer(&1.id))
      |> Enum.map(& &1.id)
      |> Enum.sort()

    Enum.chunk_while(cs, {c, c}, &chunk_fun/2, &after_fun/1)
  end

  defp chunk_fun(c, {first, last}) do
    if c === last + 1 do
      {:cont, {first, c}}
    else
      {:cont, first..last, {c, c}}
    end
  end

  defp after_fun({first, last}) do
    {:cont, first..last, nil}
  end
end
