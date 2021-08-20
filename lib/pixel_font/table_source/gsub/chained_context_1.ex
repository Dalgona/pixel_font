defmodule PixelFont.TableSource.GSUB.ChainedContext1 do
  alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext1

  defstruct rulesets: %{}

  @type t :: %__MODULE__{rulesets: ChainedSequenceContext1.rulesets()}

  defimpl PixelFont.TableSource.GSUB.Subtable do
    alias PixelFont.TableSource.GSUB.ChainedContext1
    alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext1

    @spec compile(ChainedContext1.t(), keyword()) :: binary()
    def compile(subtable, opts) do
      lookup_indices = opts[:lookup_indices]

      ChainedSequenceContext1.compile(subtable.rulesets, lookup_indices)
    end
  end
end
