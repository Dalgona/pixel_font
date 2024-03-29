defmodule PixelFont.TableSource.OTFLayout.GlyphCoverage do
  require PixelFont.Util, as: Util
  import Util, only: :macros
  alias PixelFont.Glyph

  defstruct glyphs: []

  @type t :: %__MODULE__{glyphs: [Glyph.id()]}
  @type source :: [Glyph.id() | Range.t() | source()]

  @spec of(source()) :: t()
  def of(glyphs) do
    %__MODULE__{
      glyphs:
        glyphs
        |> List.flatten()
        |> Enum.map(fn
          %Range{} = range -> Enum.to_list(range)
          x -> x
        end)
        |> List.flatten()
    }
  end

  @spec compile(t(), keyword()) :: binary()
  def compile(%__MODULE__{glyphs: glyphs}, opts \\ []) do
    glyph_idx = glyphs |> get_gids(opts[:internal] || false) |> Enum.sort()
    chunked_glyph_idx = chunk_glyph_idx(glyph_idx)
    fmt1_words = 2 + length(glyph_idx)
    fmt2_words = 2 + 3 * length(chunked_glyph_idx)

    if fmt1_words < fmt2_words do
      compile_format1(glyph_idx)
    else
      compile_format2(chunked_glyph_idx)
    end
  end

  @spec compile_coverage_records([[t()]], integer()) :: {[iodata()], [iodata()]}
  def compile_coverage_records(sequences, offset_base) do
    {_, offsets, coverages} =
      sequences
      |> Enum.reduce({offset_base, [], []}, fn seq, {pos, data1, data2} ->
        {next_pos, offsets, data} =
          seq
          |> Enum.map(&compile/1)
          |> Util.offsetted_binaries(pos, & &1)

        offsets_bin = [<<length(offsets)::16>>, offsets]

        {next_pos, [offsets_bin | data1], [data | data2]}
      end)

    {Enum.reverse(offsets), Enum.reverse(coverages)}
  end

  @spec get_gids([value], boolean()) :: [integer()] when value: integer() | binary()
  defp get_gids(glyphs, internal?)
  defp get_gids(glyphs, true), do: glyphs
  defp get_gids(glyphs, false), do: Enum.map(glyphs, &gid!(&1))

  @spec chunk_glyph_idx([integer()]) :: [[integer()]]
  defp chunk_glyph_idx(glyph_idx) do
    {chunk, chunks} =
      Enum.reduce(glyph_idx, {[], []}, fn index, {chunk, chunks} ->
        prev = List.first(chunk) || index - 1

        if index - prev === 1 do
          {[index | chunk], chunks}
        else
          {[index], [Enum.reverse(chunk) | chunks]}
        end
      end)

    Enum.reverse([Enum.reverse(chunk) | chunks])
  end

  @spec compile_format1([integer()]) :: binary()
  defp compile_format1(glyph_idx) do
    IO.iodata_to_binary([
      <<1::16>>,
      <<length(glyph_idx)::16>>,
      Enum.map(glyph_idx, &<<&1::16>>)
    ])
  end

  @spec compile_format2([[integer()]]) :: binary()
  defp compile_format2(chunked_glyph_idx) do
    {range_records, _} =
      Enum.reduce(chunked_glyph_idx, {[], 0}, fn [x | xs], {records, next} ->
        rest_len = length(xs)

        record = [
          <<x::16>>,
          <<x + rest_len::16>>,
          <<next::16>>
        ]

        {[record | records], next + rest_len + 1}
      end)

    IO.iodata_to_binary([
      <<2::16>>,
      <<length(range_records)::16>>,
      Enum.reverse(range_records)
    ])
  end
end
