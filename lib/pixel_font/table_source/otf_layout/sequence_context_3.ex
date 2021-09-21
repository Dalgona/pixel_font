defmodule PixelFont.TableSource.OTFLayout.SequenceContext3 do
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup
  alias PixelFont.Util

  defstruct input: [], lookup_records: []

  @type t :: %__MODULE__{
          input: [GlyphCoverage.t()],
          lookup_records: [{integer(), Lookup.id()}]
        }

  @spec compile(t(), keyword()) :: binary()
  def compile(%__MODULE__{} = subtable, opts) do
    lookup_indices = opts[:lookup_indices]
    lookup_record_count = length(subtable.lookup_records)
    coverage_offset_base = 6 + length(subtable.input) * 2 + lookup_record_count * 4

    compiled_lookup_records =
      Enum.map(subtable.lookup_records, fn {glyph_pos, lookup_id} ->
        <<glyph_pos::16, lookup_indices[lookup_id]::16>>
      end)

    {_, coverage_offsets, compiled_coverages} =
      Util.offsetted_binaries(subtable.input, coverage_offset_base, &GlyphCoverage.compile/1)

    IO.iodata_to_binary([
      # format
      <<3::16>>,
      # glyphCount
      <<length(subtable.input)::16>>,
      # seqLookupCount
      <<lookup_record_count::16>>,
      # coverageOffsets[]
      coverage_offsets,
      # seqLookupRecords[]
      compiled_lookup_records,
      # Coverage tables
      compiled_coverages
    ])
  end

  defimpl PixelFont.TableSource.GPOS.Subtable do
    alias PixelFont.TableSource.OTFLayout.SequenceContext3

    defdelegate compile(subtable, opts), to: SequenceContext3
  end

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.OTFLayout.SequenceContext3

    defdelegate compile(subtable, opts), to: SequenceContext3
  end
end
