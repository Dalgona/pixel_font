defmodule PixelFont.TableSource.GPOS do
  alias PixelFont.CompiledTable
  alias PixelFont.Font.Metrics
  alias PixelFont.TableSource.GPOSGSUB
  alias PixelFont.TableSource.GPOS.Subtable
  alias PixelFont.TableSource.OTFLayout.FeatureList
  alias PixelFont.TableSource.OTFLayout.LookupList
  alias PixelFont.TableSource.OTFLayout.ScriptList

  defstruct script_list: %ScriptList{},
            feature_list: %FeatureList{},
            lookup_list: %LookupList{},
            feature_indices: %{},
            lookup_indices: %{}

  @type t :: %__MODULE__{
          script_list: ScriptList.t(),
          feature_list: FeatureList.t(),
          lookup_list: LookupList.t(),
          feature_indices: GPOSGSUB.feature_indices(),
          lookup_indices: GPOSGSUB.lookup_indices()
        }

  @spec from_lookups([module()]) :: t()
  def from_lookups(lookup_modules) do
    struct!(__MODULE__, GPOSGSUB.__from_lookups__(lookup_modules))
  end

  @spec compile(t(), Metrics.t()) :: CompiledTable.t()
  defdelegate compile(gpos, metrics), to: GPOSGSUB

  @spec compile_subtable(map(), integer(), keyword()) :: binary()
  def compile_subtable(subtable, _lookup_type, opts) do
    Subtable.compile(subtable, opts)
  end
end
