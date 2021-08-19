defmodule PixelFont.TableSource.GSUB.Multiple1 do
  alias PixelFont.Glyph

  defstruct substitutions: []

  @type t :: %__MODULE__{substitutions: [{Glyph.id(), [Glyph.id()]}]}

  defimpl PixelFont.TableSource.GSUB.Subtable do
    require PixelFont.Util, as: Util
    import Util, only: :macros
    alias PixelFont.TableSource.GSUB.Multiple1
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage

    @spec compile(Multiple1.t(), keyword()) :: binary()
    def compile(subtable, _opts) do
      {src_glyphs, sequences} =
        subtable.substitutions
        |> map_indices()
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.unzip()

      coverage = src_glyphs |> GlyphCoverage.of() |> GlyphCoverage.compile(internal: true)
      sequence_count = length(sequences)
      coverage_offset = 6 + 2 * sequence_count
      offset_base = coverage_offset + byte_size(coverage)

      {_, offsets, compiled_sequence_tables} =
        Util.offsetted_binaries(sequences, offset_base, &compile_sequence_table/1)

      IO.iodata_to_binary([
        # substFormat
        <<1::16>>,
        # coverageOffset
        <<coverage_offset::16>>,
        # sequenceCount
        <<sequence_count::16>>,
        # sequenceOffsets[]
        offsets,
        # Coverage Table
        coverage,
        # Sequence Tables
        compiled_sequence_tables
      ])
    end

    @spec map_indices([{Glyph.id(), [Glyph.id()]}]) :: [{integer(), [integer()]}]
    defp map_indices(substitutions) do
      Enum.map(substitutions, fn {from_glyph_id, to_glyph_ids} ->
        {gid!(from_glyph_id), Enum.map(to_glyph_ids, &gid!/1)}
      end)
    end

    @spec compile_sequence_table([integer()]) :: iodata()
    defp compile_sequence_table(sequence)

    defp compile_sequence_table([]) do
      raise ArgumentError, "the output glyph sequence must not be empty"
    end

    defp compile_sequence_table(sequence) do
      [
        # glyphCount
        <<length(sequence)::16>>,
        # substituteGlyphIDs[]
        Enum.map(sequence, &<<&1::16>>)
      ]
    end
  end
end
