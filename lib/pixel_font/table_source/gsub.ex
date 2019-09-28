defmodule PixelFont.TableSource.GSUB do
  alias PixelFont.TableSource.OTFLayout.ScriptList
  alias PixelFont.TableSource.OTFLayout.FeatureList
  alias PixelFont.TableSource.OTFLayout.LookupList

  defstruct ~w(script_list feature_list lookup_list)a

  @type t :: %__MODULE__{
          script_list: ScriptList.t(),
          feature_list: FeatureList.t(),
          lookup_list: LookupList.t()
        }
end
