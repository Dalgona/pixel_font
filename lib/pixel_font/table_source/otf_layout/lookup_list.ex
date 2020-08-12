defmodule PixelFont.TableSource.OTFLayout.LookupList do
  alias PixelFont.TableSource.OTFLayout.Lookup
  alias PixelFont.Util

  defstruct lookups: []

  @type t :: %__MODULE__{lookups: [Lookup.t()]}

  @spec compile(t(), keyword()) :: binary()
  def compile(%{lookups: lookups}, opts) do
    lookup_count = length(lookups)
    offset_base = 2 + lookup_count * 2

    {_, offsets, tables} =
      Util.offsetted_binaries(lookups, offset_base, &Lookup.compile(&1, opts))

    IO.iodata_to_binary([<<lookup_count::16>>, offsets, tables])
  end
end
