defmodule PixelFont.TableSource.GPOS do
  alias PixelFont.CompiledTable
  alias PixelFont.TableSource.GPOS.Subtable
  alias PixelFont.TableSource.OTFLayout.FeatureList
  alias PixelFont.TableSource.OTFLayout.LookupList
  alias PixelFont.TableSource.OTFLayout.ScriptList
  alias PixelFont.Util

  defstruct script_list: %ScriptList{},
            feature_list: %FeatureList{},
            lookup_list: %LookupList{},
            feature_indices: %{},
            lookup_indices: %{}

  @type t :: %__MODULE__{
          script_list: ScriptList.t(),
          feature_list: FeatureList.t(),
          lookup_list: LookupList.t(),
          feature_indices: feature_indices(),
          lookup_indices: lookup_indices()
        }

  @type feature_indices :: %{optional({<<_::4>>, term()}) => integer()}
  @type lookup_indices :: %{optional(binary()) => integer()}

  @spec compile(t()) :: CompiledTable.t()
  def compile(gpos) do
    gpos = preprocess(gpos)
    offset_base = 14

    list_compile_opts = [
      feature_indices: gpos.feature_indices,
      lookup_indices: gpos.lookup_indices
    ]

    {_, offsets, compiled_lists} =
      [gpos.script_list, gpos.feature_list, gpos.lookup_list]
      |> Util.offsetted_binaries(offset_base, fn list ->
        list.__struct__.compile(list, list_compile_opts)
      end)

    data = [
      # GPOS version 1.1
      <<1::16, 1::16>>,
      offsets,
      # FeatureVariationsOffset (Not used yet)
      <<0::32>>,
      compiled_lists
    ]

    CompiledTable.new("GPOS", IO.iodata_to_binary(data))
  end

  @spec compile_subtable(map(), integer(), keyword()) :: binary()
  def compile_subtable(subtable, _lookup_type, opts) do
    Subtable.compile(subtable, opts)
  end

  @spec preprocess(t()) :: t()
  defp preprocess(gpos) do
    %__MODULE__{
      gpos
      | script_list: ScriptList.sort(gpos.script_list),
        feature_list: FeatureList.sort(gpos.feature_list)
    }
    |> populate_indices()
  end

  @spec populate_indices(t()) :: t()
  defp populate_indices(gpos) do
    %__MODULE__{
      gpos
      | feature_indices: index_map(gpos.feature_list.features, &{&1.tag, &1.name}),
        lookup_indices: index_map(gpos.lookup_list.lookups, & &1.name)
    }
  end

  defp index_map(enumerable, fun) do
    enumerable
    |> Enum.with_index()
    |> Enum.map(fn {item, index} -> {fun.(item), index} end)
    |> Map.new()
  end
end
