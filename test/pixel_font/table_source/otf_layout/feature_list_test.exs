defmodule PixelFont.TableSource.OTFLayout.FeatureListTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.OTFLayout.Feature
  alias PixelFont.TableSource.OTFLayout.FeatureList

  describe "compile/2" do
    test "compiles a OpenType feature list table" do
      feature_list = %FeatureList{
        features: [
          %Feature{tag: "calt", name: "Feature 1", lookups: ["Lookup 1"]},
          %Feature{tag: "liga", name: "Feature 2", lookups: ["Lookup 1", "Lookup 2"]}
        ]
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}
      compiled_list = FeatureList.compile(feature_list, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          2,
          [["calt", 14], ["liga", 20]],
          [
            # Feature tables
            [0, 1, [10]],
            [0, 2, [10, 20]]
          ]
        ])

      assert compiled_list === expected
    end
  end

  describe "concat/2" do
    test "concatenates two feature lists" do
      feature_1 = %Feature{tag: "calt", name: "Feature 1", lookups: []}
      feature_2 = %Feature{tag: "liga", name: "Feature 2", lookups: []}
      feature_list_1 = %FeatureList{features: [feature_1]}
      feature_list_2 = %FeatureList{features: [feature_2]}
      concatenated = FeatureList.concat(feature_list_1, feature_list_2)

      assert concatenated.features === [feature_1, feature_2]
    end
  end

  describe "sort/1" do
    test "sorts a feature list by feature tag in ascending order" do
      feature_list = %FeatureList{
        features: [
          %Feature{tag: "frac", name: "Feature 1", lookups: []},
          %Feature{tag: "tnum", name: "Feature 2", lookups: []},
          %Feature{tag: "aalt", name: "Feature 3", lookups: []}
        ]
      }

      sorted_list = FeatureList.sort(feature_list)

      assert Enum.map(sorted_list.features, & &1.tag) === ~w(aalt frac tnum)
    end
  end
end
