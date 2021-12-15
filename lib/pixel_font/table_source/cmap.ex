defmodule PixelFont.TableSource.Cmap do
  require PixelFont.Util, as: Util
  import Util, only: :macros
  alias PixelFont.CompiledTable
  alias PixelFont.Glyph
  alias PixelFont.GlyphStorage
  alias PixelFont.TableSource.Name.Definitions, as: Defs

  @spec compile() :: CompiledTable.t()
  def compile do
    all_glyphs = GlyphStorage.all()

    offset = 20
    {variations_record, variations_subtable} = compile_variation_sequences(all_glyphs, offset)
    offset = offset + byte_size(variations_subtable)
    {encoding_record, encoding_subtable} = compile_encoding_subtable(all_glyphs, offset)

    data = [
      # 'cmap' table version
      <<0::16>>,
      # Number of subtable(s)
      <<2::16>>,
      # Subtable records
      [
        variations_record,
        encoding_record
      ],
      # Subtables
      [
        variations_subtable,
        encoding_subtable
      ]
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
    all_glyphs
    |> Enum.filter(&is_integer(&1.id))
    |> Enum.map(& &1.id)
    |> chunk_into_ranges()
  end

  defp compile_variation_sequences(all_glyphs, offset) do
    variation_sequences = build_variation_sequences(all_glyphs)
    platform_id = Defs.platform_id(:unicode)
    encoding_id = Defs.encoding_id(:unicode, :unicode_vs)
    selectors_count = length(variation_sequences)
    offset_base = 10 + 11 * selectors_count

    [compiled_records, compiled_tables] =
      variation_sequences
      |> compile_uvs_tables(offset_base)
      |> Enum.unzip()
      |> Tuple.to_list()
      |> Enum.map(&IO.iodata_to_binary/1)

    subtable_record = <<platform_id::16, encoding_id::16, offset::32>>

    subtable =
      IO.iodata_to_binary([
        # Subtable format 14: Unicode Variation Sequences
        <<14::16>>,
        # length
        <<offset_base + byte_size(compiled_tables)::32>>,
        # numVarSelectorRecords
        <<selectors_count::32>>,
        # varSelector[]
        [compiled_records],
        # Default/Non-default UVS Tables
        [compiled_tables]
      ])

    {subtable_record, subtable}
  end

  defp build_variation_sequences(all_glyphs) do
    {default_uvs, non_default_uvs} =
      all_glyphs
      |> Enum.filter(& &1.variations)
      |> Enum.map(fn %Glyph{id: id, variations: variations} ->
        default_variation = selector_codepoint(variations.default)

        non_default_variations =
          Enum.map(variations.non_default, fn {vs_num, to_glyph} ->
            {selector_codepoint(vs_num), {id, gid!(to_glyph)}}
          end)

        {{default_variation, id}, non_default_variations}
      end)
      |> Enum.unzip()

    default_uvs = consolidate_default_uvs(default_uvs)
    non_default_uvs = consolidate_non_default_uvs(non_default_uvs)

    default_uvs
    |> Map.merge(non_default_uvs, fn _key, map1, map2 ->
      Map.merge(map1, map2, fn _key, list1, list2 -> list1 ++ list2 end)
    end)
    |> Enum.sort_by(&elem(&1, 0))
  end

  @spec selector_codepoint(1..256) :: 0..0xFFFFFF
  defp selector_codepoint(vs_num)
  defp selector_codepoint(vs_num) when vs_num in 1..16, do: 0xFDFF + vs_num
  defp selector_codepoint(vs_num) when vs_num in 17..256, do: 0x0E00EF + vs_num

  defp consolidate_default_uvs(default_uvs) do
    default_uvs
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {key, values} ->
      unicode_ranges =
        values
        |> chunk_into_ranges()
        |> Enum.map(fn first..last -> {first, last - first} end)

      {key, %{default: unicode_ranges}}
    end)
  end

  defp consolidate_non_default_uvs(non_default_uvs) do
    non_default_uvs
    |> List.flatten()
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
    |> Map.new(fn {key, value} -> {key, %{non_default: value}} end)
  end

  defp compile_uvs_tables(variation_sequences, offset, acc \\ [])
  defp compile_uvs_tables([], _offset, acc), do: Enum.reverse(acc)

  defp compile_uvs_tables([{selector, map} | seqs], offset, acc) do
    {default_offset, default_uvs} = compile_default_uvs(map[:default], offset)

    {non_default_offset, non_default_uvs} =
      compile_non_default_uvs(map[:non_default], offset + byte_size(default_uvs))

    record = <<selector::24, default_offset::32, non_default_offset::32>>
    tables = default_uvs <> non_default_uvs

    compile_uvs_tables(seqs, offset + byte_size(tables), [{record, tables} | acc])
  end

  defp compile_default_uvs(maybe_uvs, offset)
  defp compile_default_uvs(nil, _offset), do: {0, <<>>}

  defp compile_default_uvs(unicode_ranges, offset) do
    table =
      IO.iodata_to_binary([
        <<length(unicode_ranges)::32>>,
        unicode_ranges
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(fn {start, count} -> <<start::24, count::8>> end)
      ])

    {offset, table}
  end

  defp compile_non_default_uvs(maybe_uvs, offset)
  defp compile_non_default_uvs(nil, _offset), do: {0, <<>>}

  defp compile_non_default_uvs(mappings, offset) do
    table =
      IO.iodata_to_binary([
        <<length(mappings)::32>>,
        mappings
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(fn {base_unicode, gid} -> <<base_unicode::24, gid::16>> end)
      ])

    {offset, table}
  end

  defp chunk_into_ranges(values) do
    [x | xs] = Enum.sort(values)

    Enum.chunk_while(
      xs,
      {x, x},
      fn x, {first, last} ->
        if x === last + 1 do
          {:cont, {first, x}}
        else
          {:cont, first..last, {x, x}}
        end
      end,
      fn {first, last} -> {:cont, first..last, nil} end
    )
  end
end
