defmodule PixelFont.TableSource.OTFLayout.Feature do
  alias PixelFont.TableSource.OTFLayout.Lookup

  defstruct ~w(tag name lookups)a

  @type t :: %__MODULE__{tag: tag(), name: id(), lookups: [Lookup.id()]}
  @type tag :: <<_::32>>
  @type id :: term()

  @spec compile(t(), keyword()) :: binary()
  def compile(%{lookups: lookups}, opts) do
    lookup_indices = opts[:lookup_indices]

    data = [
      # FeatureParams (Reserved)
      <<0::16>>,
      <<length(lookups)::16>>,
      Enum.map(lookups, &<<lookup_indices[&1]::16>>)
    ]

    IO.iodata_to_binary(data)
  end
end
