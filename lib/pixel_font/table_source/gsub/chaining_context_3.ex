defmodule PixelFont.TableSource.GSUB.ChainingContext3 do
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.Lookup

  defstruct backtrack: [], input: [], lookahead: [], lookup_records: []

  @type t :: %__MODULE__{
          backtrack: [GlyphCoverage.t()],
          input: [GlyphCoverage.t()],
          lookahead: [GlyphCoverage.t()],
          lookup_records: [{integer(), Lookup.id()}]
        }

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.GSUB.ChainingContext3
    alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext3

    @spec compile(ChainingContext3.t(), keyword()) :: binary()
    def compile(subtable, opts) do
      lookup_indices = opts[:lookup_indices]

      ChainedSequenceContext3.compile(subtable, lookup_indices)
    end
  end
end
