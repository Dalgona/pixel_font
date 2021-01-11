defmodule PixelFont.TableSource.GSUB.Single2 do
  defstruct [:substitutions]

  @type t :: %__MODULE__{substitutions: [{glyph_id(), glyph_id()}]}
  @typep glyph_id :: integer() | binary()

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage
    alias PixelFont.TableSource.GSUB.Single2

    @spec compile(Single2.t(), keyword()) :: binary()
    def compile(subtable, _opts) do
      {from_glyphs, to_glyphs} =
        subtable.substitutions
        |> Enum.sort(&(elem(&1, 0) <= elem(&2, 0)))
        |> Enum.unzip()

      coverage = GlyphCoverage.of(from_glyphs)
      coverage_offset = 6 + length(from_glyphs) * 2

      IO.iodata_to_binary([
        <<2::16>>,
        <<coverage_offset::16>>,
        <<length(from_glyphs)::16>>,
        Enum.map(to_glyphs, &<<&1::16>>),
        GlyphCoverage.compile(coverage, internal: true)
      ])
    end
  end
end
