defmodule PixelFont.TableSource.GSUB.Alternate1 do
  alias PixelFont.Glyph

  defstruct [:alternatives]

  @type t :: %__MODULE__{alternatives: %{optional(Glyph.id()) => [Glyph.id()]}}

  defimpl PixelFont.TableSource.GSUB.Subtable do
    require PixelFont.Util
    import PixelFont.Util
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage
    alias PixelFont.TableSource.GSUB.Alternate1

    @spec compile(Alternate1.t(), keyword()) :: binary()
    def compile(subtable, _opts) do
      mapped_alternatives =
        subtable.alternatives
        |> Enum.map(fn {gid, alt_gids} -> {gid!(gid), Enum.map(alt_gids, &gid!/1)} end)
        |> Enum.sort_by(&elem(&1, 0))

      compiled_coverage =
        mapped_alternatives
        |> Enum.map(&elem(&1, 0))
        |> GlyphCoverage.of()
        |> GlyphCoverage.compile(internal: true)

      alt_sets_count = length(mapped_alternatives)
      coverage_offset = 6 + 2 * alt_sets_count
      alt_sets_base = coverage_offset + byte_size(compiled_coverage)

      {_pos, alt_set_offsets, alt_sets} =
        mapped_alternatives
        |> Enum.map(&elem(&1, 1))
        |> offsetted_binaries(alt_sets_base, fn alt_gids ->
          [
            # glyphCount
            <<length(alt_gids)::16>>,
            # alternateGlyphIDs
            Enum.map(alt_gids, &<<&1::16>>)
          ]
        end)

      IO.iodata_to_binary([
        # substFormat
        <<1::16>>,
        # coverageOffset
        <<coverage_offset::16>>,
        # alternateSetCount
        <<alt_sets_count::16>>,
        # alternateSetOffsets
        alt_set_offsets,
        # Coverage Table
        compiled_coverage,
        # Alternate Sets
        alt_sets
      ])
    end
  end
end
