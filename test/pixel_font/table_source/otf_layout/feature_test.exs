defmodule PixelFont.TableSource.OTFLayout.FeatureTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.OTFLayout.Feature

  describe "compile/2" do
    test "compiles a OpenType feature table" do
      feature = %Feature{
        tag: "liga",
        name: "Test Feature",
        lookups: ["Lookup 1", "Lookup 2"]
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}
      compiled_feature = Feature.compile(feature, lookup_indices: lookup_indices)
      expected = to_wordstring([0, 2, [10, 20]])

      assert compiled_feature === expected
    end
  end
end
