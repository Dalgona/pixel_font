defmodule PixelFont.TableSource.OTFLayout.ChainedSequenceContext3 do
  alias PixelFont.TableSource.GPOSGSUB
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  @type context :: %{
          backtrack: [GlyphCoverage.t()],
          input: [GlyphCoverage.t()],
          lookahead: [GlyphCoverage.t()],
          lookup_records: [{integer(), Lookup.id()}]
        }

  @spec compile(context(), GPOSGSUB.lookup_indices()) :: binary()
  def compile(context, lookup_indices) do
    lookup_record_count = length(context.lookup_records)
    sequences = [context.backtrack, context.input, context.lookahead]
    context_length = sequences |> Enum.map(&length/1) |> Enum.sum()
    offset_base = 10 + context_length * 2 + lookup_record_count * 4
    {offsets, coverages} = GlyphCoverage.compile_coverage_records(sequences, offset_base)

    compiled_lookup_records =
      Enum.map(context.lookup_records, fn {glyph_pos, lookup_id} ->
        <<glyph_pos::16, lookup_indices[lookup_id]::16>>
      end)

    IO.iodata_to_binary([
      # format
      <<3::16>>,
      # {backtrack,input,lookahead}{GlyphCount,CoverageOffsets[]}
      offsets,
      # seqLookupCount
      <<lookup_record_count::16>>,
      # seqLookupRecords[]
      compiled_lookup_records,
      # Coverage tables
      coverages
    ])
  end
end
