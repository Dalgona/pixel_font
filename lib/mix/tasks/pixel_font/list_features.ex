defmodule Mix.Tasks.PixelFont.ListFeatures do
  use Mix.Task
  alias Mix.Tasks.PixelFont.Common
  alias PixelFont.GlyphStorage.GenServer, as: GlyphStorage
  alias PixelFont.TableSource.GPOS
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.OTFLayout.Feature
  alias PixelFont.TableSource.OTFLayout.LanguageSystem
  alias PixelFont.TableSource.OTFLayout.Script

  @impl true
  def run(args) do
    Mix.Task.run("compile")

    font = Common.get_font(args)
    {:ok, _pid} = GlyphStorage.start_link(font.glyph_sources)
    gpos = GPOS.from_lookups(font.gpos_lookups)
    gsub = GSUB.from_lookups(font.gsub_lookups)
    :ok = GenServer.stop(GlyphStorage)

    IO.puts("=== List of GPOS Features ===")
    print_features(gpos)
    IO.puts("\n=== List of GSUB Features ===")
    print_features(gsub)
  end

  @spec print_features(GPOS.t() | GSUB.t()) :: :ok
  defp print_features(gpos_or_gsub) do
    %{
      feature_list: %{features: features},
      script_list: %{scripts: scripts}
    } = gpos_or_gsub

    langs = langs_by_features(scripts)

    features
    |> Enum.sort_by(& &1.tag)
    |> Enum.map(fn %Feature{} = feature ->
      [
        ["Feature ", :green, ?', feature.tag, ?', :reset, ?\n],
        ["  Applied to: ", Map.get(langs, feature.name, "none")],
        [?\n, "  Lookups: ", ?\n],
        feature.lookups
        |> Enum.map(&["    ", :yellow, &1])
        |> Enum.intersperse(?\n),
        :reset
      ]
    end)
    |> Enum.intersperse(?\n)
    |> IO.ANSI.format()
    |> IO.puts()
  end

  defp langs_by_features(scripts) do
    scripts
    |> Enum.map(&flatten_script/1)
    |> List.flatten()
    |> Enum.group_by(&elem(&1, 2))
    |> Map.new(fn {feature_id, flattened_langs} ->
      script_langs =
        flattened_langs
        |> Enum.map(fn {script_tag, lang_tag, _} ->
          [:cyan, script_tag, :reset, "(", lang_tag, ")"]
        end)
        |> Enum.intersperse(", ")

      {feature_id, script_langs}
    end)
  end

  defp flatten_script(%Script{} = script) do
    [script.default_language | script.languages]
    |> Enum.map(&consolidate_features_in_lang/1)
    |> Enum.map(fn {lang_tag, feature_ids} ->
      Enum.map(feature_ids, &{script.tag, lang_tag, &1})
    end)
    |> List.flatten()
  end

  defp consolidate_features_in_lang(%LanguageSystem{} = lang) do
    case lang.required_feature do
      nil -> {lang.tag, lang.features}
      feature_id -> {lang.tag, [feature_id | lang.features]}
    end
  end
end
