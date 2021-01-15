defmodule PixelFont.TableSource.OTFLayout.Lookup do
  alias PixelFont.Util
  alias PixelFont.TableSource.OTFLayout.{Feature, LanguageSystem, Script}

  defstruct ~w(owner type name subtables features)a

  @type t :: %__MODULE__{
          owner: module(),
          type: integer(),
          name: id(),
          subtables: [map()],
          features: features()
        }

  @type id :: term()

  @type features :: %{
          optional(Feature.tag()) => %{
            optional(Script.tag()) => [:default | LanguageSystem.tag()]
          }
        }

  @spec compile(t(), keyword()) :: binary()
  def compile(%{subtables: subtables} = lookup, opts) do
    subtable_count = length(subtables)

    # Size of MarkFilteringSet: 0
    offset_base = 6 + subtable_count * 2 + 0

    {_, offsets, compiled_subtables} =
      Util.offsetted_binaries(subtables, offset_base, fn subtable ->
        lookup.owner.compile_subtable(subtable, lookup.type, opts)
      end)

    data = [
      <<lookup.type::16>>,
      # LookupFlag (Not used yet)
      <<0::16>>,
      <<subtable_count::16>>,
      offsets,
      # MarkFilteringSet (Not present)
      "",
      compiled_subtables
    ]

    IO.iodata_to_binary(data)
  end
end
