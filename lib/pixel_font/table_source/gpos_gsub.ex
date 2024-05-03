defmodule PixelFont.TableSource.GPOSGSUB do
  require PixelFont.Util
  import PixelFont.Util, only: :macros
  alias PixelFont.CompiledTable
  alias PixelFont.Font.Metrics
  alias PixelFont.TableSource.GPOS
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.OTFLayout.Feature
  alias PixelFont.TableSource.OTFLayout.FeatureList
  alias PixelFont.TableSource.OTFLayout.LanguageSystem
  alias PixelFont.TableSource.OTFLayout.Lookup
  alias PixelFont.TableSource.OTFLayout.LookupList
  alias PixelFont.TableSource.OTFLayout.Script
  alias PixelFont.TableSource.OTFLayout.ScriptList
  alias PixelFont.Util

  @type t :: GPOS.t() | GSUB.t()
  @type feature_indices :: %{optional(Feature.id()) => integer()}
  @type lookup_indices :: %{optional(binary()) => integer()}

  @spec __from_lookups__([module()]) :: %{
          lookup_list: LookupList.t(),
          feature_list: FeatureList.t(),
          script_list: ScriptList.t()
        }
  def __from_lookups__(lookup_modules) do
    lookup_list =
      lookup_modules
      |> Enum.map(& &1.lookups())
      |> Enum.reduce(&LookupList.concat(&2, &1))

    {features, feature_associations} =
      lookup_list.lookups
      |> associate_lookups()
      |> make_features()

    %{
      lookup_list: lookup_list,
      feature_list: %FeatureList{features: features},
      script_list: %ScriptList{scripts: make_scripts(feature_associations)}
    }
  end

  @typep lookup_association :: {Feature.tag(), lookups_to_lang()}
  @typep lookups_to_lang :: %{optional([Lookup.id()]) => script_lang()}
  @typep script_lang :: {Script.tag(), language_tag()}
  @typep language_tag :: :default | LanguageSystem.tag()
  @typep feature_association :: {script_lang(), Feature.id()}

  @spec associate_lookups([Lookup.t()]) :: [lookup_association()]
  defp associate_lookups(lookups) do
    lookups
    |> Enum.reduce(%{}, fn %Lookup{} = lookup, acc ->
      lookup.features
      |> get_assoc_keys()
      |> Map.new(&{&1, [lookup.name]})
      |> Map.merge(acc, fn _, names1, names2 -> names2 ++ names1 end)
    end)
    |> Enum.group_by(&elem!(&1, [0, 0]), &{elem!(&1, [0, 1]), elem(&1, 1)})
    |> Enum.map(fn {feature_tag, list} ->
      {feature_tag, Enum.group_by(list, &elem(&1, 1), &elem(&1, 0))}
    end)
  end

  @spec get_assoc_keys([Feature.t()]) :: [{Feature.tag(), {script_lang()}}]
  defp get_assoc_keys(features) do
    Enum.flat_map(features, fn {feat_tag, scripts} ->
      Enum.flat_map(scripts, fn {script_tag, languages} ->
        Enum.map(languages, &{feat_tag, {script_tag, &1}})
      end)
    end)
  end

  @spec make_features([lookup_association()]) :: {[Feature.t()], [feature_association()]}
  def make_features(lookup_associations) do
    {features, assocs} =
      lookup_associations
      |> Enum.reduce({[], []}, fn {feature_tag, lookups_to_lang}, {feats0, assocs0} ->
        {feats1, assocs1} = do_make_features(feature_tag, lookups_to_lang)

        {feats0 ++ feats1, assocs0 ++ assocs1}
      end)

    {features, List.flatten(assocs)}
  end

  @spec do_make_features(Feature.tag(), lookups_to_lang()) ::
          {[Feature.t()], [feature_association()]}
  defp do_make_features(feature_tag, lookups_to_lang) do
    lookups_to_lang
    |> Enum.map(fn {lookup_names, script_langs} ->
      feature_id = make_ref()
      feature = %Feature{tag: feature_tag, name: feature_id, lookups: lookup_names}

      {feature, Enum.map(script_langs, &{&1, feature_id})}
    end)
    |> Enum.unzip()
  end

  @spec make_scripts([feature_association()]) :: [Script.t()]
  defp make_scripts(feature_associations) do
    feature_associations
    |> Enum.group_by(&elem!(&1, [0, 0]), &{elem!(&1, [0, 1]), elem(&1, 1)})
    |> Enum.map(&make_script/1)
  end

  @spec make_script({Script.tag(), [{language_tag(), Feature.id()}]}) :: Script.t()
  defp make_script({script_tag, lang_feats}) do
    {dflt_lang_feature, lang_features} =
      lang_feats
      |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
      |> Map.pop(:default)

    default_language = dflt_lang_feature && make_language("dflt", dflt_lang_feature)
    languages = Enum.map(lang_features, &make_language(elem(&1, 0), elem(&1, 1)))

    %Script{
      tag: script_tag,
      default_language: default_language,
      languages: languages
    }
  end

  @spec make_language(language_tag(), [Feature.id()]) :: LanguageSystem.t()
  defp make_language(tag, features), do: %LanguageSystem{tag: tag, features: features}

  @spec compile(t(), Metrics.t()) :: CompiledTable.t()
  def compile(%struct{} = table, %Metrics{} = metrics) when struct in [GPOS, GSUB] do
    table = preprocess(table)
    offset_base = 14

    list_compile_opts = [
      metrics: metrics,
      feature_indices: table.feature_indices,
      lookup_indices: table.lookup_indices
    ]

    {_, offsets, compiled_lists} =
      [table.script_list, table.feature_list, table.lookup_list]
      |> Util.offsetted_binaries(offset_base, fn list ->
        list.__struct__.compile(list, list_compile_opts)
      end)

    data = [
      # GPOS version 1.1, or GSUB version 1.1
      <<1::16, 1::16>>,
      offsets,
      # FeatureVariationsOffset (Not used yet)
      <<0::32>>,
      compiled_lists
    ]

    struct
    |> Module.split()
    |> List.last()
    |> CompiledTable.new(IO.iodata_to_binary(data))
  end

  @spec preprocess(table) :: table when table: t()
  defp preprocess(%struct{} = table) when struct in [GPOS, GSUB] do
    %{
      table
      | script_list: ScriptList.sort(table.script_list),
        feature_list: FeatureList.sort(table.feature_list)
    }
    |> populate_indices()
  end

  @spec populate_indices(table) :: table when table: t()
  defp populate_indices(%struct{} = table) when struct in [GPOS, GSUB] do
    %{
      table
      | feature_indices: index_map(table.feature_list.features, & &1.name),
        lookup_indices: index_map(table.lookup_list.lookups, & &1.name)
    }
  end

  defp index_map(enumerable, fun) do
    enumerable
    |> Enum.with_index()
    |> Enum.map(fn {item, index} -> {fun.(item), index} end)
    |> Map.new()
  end
end
