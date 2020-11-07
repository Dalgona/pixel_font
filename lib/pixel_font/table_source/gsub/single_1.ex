defmodule PixelFont.TableSource.GSUB.Single1 do
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  defstruct glyphs: %GlyphCoverage{}, to: 0

  @type t :: %__MODULE__{glyphs: GlyphCoverage.t(), to: integer() | binary()}

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.GlyphStorage
    alias PixelFont.TableSource.GSUB.Single1
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage

    @spec compile(Single1.t(), keyword()) :: binary()
    def compile(subtable, _opts) do
      to_index = GlyphStorage.get(subtable.to).gid
      compiled_coverage = GlyphCoverage.compile(subtable.glyphs)
      first_id = GlyphStorage.get(hd(subtable.glyphs.glyphs)).gid

      IO.iodata_to_binary([
        # substFormat
        <<1::16>>,
        # coverageOffset
        <<6::16>>,
        # deltaGlyphID
        <<to_index - first_id::16>>,
        # Coverage Table
        compiled_coverage
      ])
    end
  end
end
