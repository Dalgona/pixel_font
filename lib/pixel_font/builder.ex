defmodule PixelFont.Builder do
  alias PixelFont.Font
  alias PixelFont.GlyphStorage.GenServer, as: GlyphStorage
  alias PixelFont.TableSource.{Cmap, Glyf, GPOS, GSUB, Head, Hmtx, Maxp, Name, OS_2, Post}

  def build_ttf(%Font{} = font) do
    {:ok, _} = GlyphStorage.start_link(font.glyph_sources)

    glyf = Glyf.generate(font.metrics)
    hmtx = Hmtx.generate(font.metrics)
    maxp = Maxp.generate()

    compiled_tables = [
      Glyf.compile(glyf),
      Hmtx.compile(hmtx, font.metrics),
      Maxp.compile(maxp),
      Name.compile(font.name_table, 0),
      Cmap.compile(),
      Post.compile(font.metrics, 2),
      OS_2.compile(font.os_2, font.metrics, 4),
      font.gpos_lookups |> GPOS.from_lookups() |> GPOS.compile(font.metrics),
      font.gsub_lookups |> GSUB.from_lookups() |> GSUB.compile(font.metrics)
    ]

    :ok = GenServer.stop(GlyphStorage)

    head = Head.compile(font.version, glyf, font.metrics)
    tables = sort_tables([head, compiled_tables])
    preamble = make_preamble(tables)
    table_record = make_table_record(tables)
    temp_ttf = make_ttf(preamble, table_record, tables)

    new_head = Head.update_checksum_adjustment(head, temp_ttf)
    new_tables = sort_tables([new_head, compiled_tables])

    make_ttf(preamble, table_record, new_tables)
  end

  defp sort_tables(compiled_tables) do
    compiled_tables
    |> List.flatten()
    |> Enum.sort(&(&1.tag < &2.tag))
  end

  defp make_preamble(compiled_tables) do
    num_tables = length(compiled_tables)
    entry_selector = num_tables |> :math.log2() |> trunc()
    search_range = (2 |> :math.pow(entry_selector) |> trunc()) * 16
    range_shift = num_tables * 16 - search_range

    [
      <<0, 1, 0, 0>>,
      <<num_tables::16>>,
      <<search_range::16>>,
      <<entry_selector::16>>,
      <<range_shift::16>>
    ]
  end

  defp make_table_record(compiled_tables) do
    offset_base = 12 + length(compiled_tables) * 16

    compiled_tables
    |> Enum.reduce({0, []}, fn table, {pos, entries} ->
      entry = [
        table.tag,
        <<table.checksum::32>>,
        <<pos + offset_base::32>>,
        <<table.real_size::32>>
      ]

      {pos + table.padded_size, [entry | entries]}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  defp make_ttf(preamble, table_record, tables) do
    IO.iodata_to_binary([preamble, table_record, Enum.map(tables, & &1.data)])
  end
end
