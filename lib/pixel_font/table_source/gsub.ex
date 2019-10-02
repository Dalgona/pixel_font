defmodule PixelFont.TableSource.GSUB do
  alias PixelFont.CompiledTable
  alias PixelFont.GlyphStorage
  alias PixelFont.TableSource.OTFLayout.ScriptList
  alias PixelFont.TableSource.OTFLayout.FeatureList
  alias PixelFont.TableSource.OTFLayout.LookupList

  defstruct ~w(script_list feature_list lookup_list)a

  @type t :: %__MODULE__{
          script_list: ScriptList.t(),
          feature_list: FeatureList.t(),
          lookup_list: LookupList.t()
        }

  @spec compile(t()) :: CompiledTable.t()
  def compile(gsub) do
    offset_base = 14

    {_, offsets, compiled_lists} =
      [gsub.script_list, gsub.feature_list, gsub.lookup_list]
      |> Enum.reduce({offset_base, [], []}, fn list, {pos, offsets, lists} ->
        compiled = list.__struct__.compile(list)

        {pos + byte_size(compiled), [pos | offsets], [compiled | lists]}
      end)

    data = [
      # GSUB version 1.1
      <<1::16, 1::16>>,
      offsets |> Enum.reverse() |> Enum.map(&<<&1::16>>),
      # FeatureVariationsOffset (Not used yet)
      <<0::32>>,
      Enum.reverse(compiled_lists)
    ]

    CompiledTable.new("GSUB", IO.iodata_to_binary(data))
  end

  @spec compile_subtable(map(), integer()) :: binary()
  def compile_subtable(subtable, lookup_type)

  # 1.1: Single Substitution, Format 1 (substitute by delta glyph IDs)
  # NOT IMPLEMENTED

  # 1.2: Single Substitution, Format 2 (substitute by glyph IDs)
  def compile_subtable(%{format: 2} = subtable, 1) do
    {from_glyphs, to_glyphs} =
      subtable.substitutions
      |> Enum.map(fn {from, to} ->
        from_id = get_glyph_id(from)
        to_id = get_glyph_id(to)

        {GlyphStorage.get(from_id).index, GlyphStorage.get(to_id).index}
      end)
      |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
      |> Enum.unzip()

    coverage = compile_coverage(from_glyphs)
    coverage_offset = 6 + length(from_glyphs) * 2

    data = [
      <<2::16>>,
      <<coverage_offset::16>>,
      <<length(from_glyphs)::16>>,
      Enum.map(to_glyphs, &<<&1::16>>),
      coverage
    ]

    IO.iodata_to_binary(data)
  end

  # 6.1: Chaining Contextual Substitution, Format 1 (GlyphID-based)
  # NOT IMPLEMENTED

  # 6.2: Chaining Contextual Substitution, Format 2 (Class-based)
  # NOT IMPLEMENTED

  # 6.3: Chaining Contextual Substitution, Format 3 (Coverage-based)
  def compile_subtable(%{format: 3} = subtable, 6) do
    sub_count = length(subtable.substitutions)
    seq_keys = ~w(backtrack input lookahead)a
    counts = seq_keys |> Enum.map(&length(subtable[&1])) |> Enum.sum()
    offset_base = 10 + counts * 2 + sub_count * 4

    {offsets, coverages} =
      seq_keys
      |> Enum.map(&subtable[&1])
      |> make_coverage_records(offset_base)

    sub_records = Enum.map(subtable.substitutions, &<<elem(&1, 0)::16, elem(&1, 1)::16>>)

    data = [
      <<3::16>>,
      Enum.reverse(offsets),
      <<sub_count::16>>,
      sub_records,
      Enum.reverse(coverages)
    ]

    IO.iodata_to_binary(data)
  end

  # 8.1 Reverse Chaining Contextual Single Substitution, Format 1 (Coverage-based)
  def compile_subtable(%{format: 1} = subtable, 8) do
    {from_glyphs, to_glyphs} =
      subtable.substitutions
      |> Enum.map(fn {from, to} ->
        from_id = get_glyph_id(from)
        to_id = get_glyph_id(to)

        {GlyphStorage.get(from_id).index, GlyphStorage.get(to_id).index}
      end)
      |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
      |> Enum.unzip()

    input_count = length(from_glyphs)
    seq_keys = ~w(backtrack lookahead)a
    counts = seq_keys |> Enum.map(&length(subtable[&1])) |> Enum.sum()
    offset_base = 10 + counts * 2 + input_count * 2

    input_coverage = compile_coverage(from_glyphs)

    {offsets, coverages} =
      seq_keys
      |> Enum.map(&subtable[&1])
      |> make_coverage_records(offset_base + byte_size(input_coverage))

    data = [
      <<1::16>>,
      <<offset_base::16>>,
      Enum.reverse(offsets),
      <<input_count::16>>,
      Enum.map(to_glyphs, &<<&1::16>>),
      input_coverage,
      Enum.reverse(coverages)
    ]

    IO.iodata_to_binary(data)
  end

  defp make_coverage_records(sequences, offset_base) do
    {_, offsets, coverages} =
      sequences
      |> Enum.reduce({offset_base, [], []}, fn seq, {pos, data1, data2} ->
        {next_pos, offsets, data} =
          seq
          |> compile_covseq()
          |> Enum.reduce({pos, [], []}, fn compiled_cov, {pos2, offsets, data} ->
            {pos2 + byte_size(compiled_cov), [pos2 | offsets], [compiled_cov | data]}
          end)

        offsets_bin = [
          <<length(offsets)::16>>,
          offsets |> Enum.reverse() |> Enum.map(&<<&1::16>>)
        ]

        {next_pos, [offsets_bin | data1], [Enum.reverse(data) | data2]}
      end)

    {offsets, coverages}
  end

  @spec compile_covseq([list()]) :: [binary()]
  defp compile_covseq(seq) do
    seq
    |> Enum.map(fn glyphs ->
      glyphs
      |> Enum.map(&GlyphStorage.get(get_glyph_id(&1)).index)
      |> Enum.sort()
      |> compile_coverage()
    end)
  end

  # TODO: Move this function to the separate module.
  @spec compile_coverage([integer()]) :: binary()
  def compile_coverage(glyph_ids) do
    data = [
      # Coverage format 1 (Glyph ID List)
      <<1::16>>,
      <<length(glyph_ids)::16>>,
      Enum.map(glyph_ids, &<<&1::16>>)
    ]

    IO.iodata_to_binary(data)
  end

  defp get_glyph_id(expr)
  defp get_glyph_id(code) when is_integer(code), do: {:unicode, code}
  defp get_glyph_id(name) when is_binary(name), do: {:name, name}
end
