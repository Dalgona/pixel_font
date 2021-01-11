defmodule PixelFont.TableSource.GSUB.Single1 do
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  defstruct gids: %GlyphCoverage{}, gid_diff: 0

  @type t :: %__MODULE__{gids: GlyphCoverage.t(), gid_diff: integer()}

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.GSUB.Single1
    alias PixelFont.TableSource.OTFLayout.GlyphCoverage

    @spec compile(Single1.t(), keyword()) :: binary()
    def compile(%Single1{} = subtable, _opts) do
      compiled_coverage = GlyphCoverage.compile(subtable.gids, internal: true)

      IO.iodata_to_binary([
        # substFormat
        <<1::16>>,
        # coverageOffset
        <<6::16>>,
        # deltaGlyphId
        <<subtable.gid_diff::16>>,
        # Coverage Table
        compiled_coverage
      ])
    end
  end
end
