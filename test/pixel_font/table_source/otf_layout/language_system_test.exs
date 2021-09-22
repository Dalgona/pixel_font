defmodule PixelFont.TableSource.OTFLayout.LanguageSystemTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.OTFLayout.LanguageSystem

  describe "compile/2" do
    test "compiles a language system table without required feature" do
      language = %LanguageSystem{
        tag: "KOR ",
        required_feature: nil,
        features: ["Feature 1", "Feature 2"]
      }

      feature_indices = %{"Feature 1" => 10, "Feature 2" => 20}
      compiled_language = LanguageSystem.compile(language, feature_indices: feature_indices)
      expected = to_wordstring([0, 0xFFFF, 2, [10, 20]])

      assert compiled_language === expected
    end

    test "compiles a language system table with a required feature" do
      language = %LanguageSystem{
        tag: "KOR ",
        required_feature: "Feature 1",
        features: ["Feature 2"]
      }

      feature_indices = %{"Feature 1" => 10, "Feature 2" => 20}
      compiled_language = LanguageSystem.compile(language, feature_indices: feature_indices)
      expected = to_wordstring([0, 10, 1, [20]])

      assert compiled_language === expected
    end
  end

  describe "concat/2 when both arguments are nil" do
    test "returns nil" do
      assert is_nil(LanguageSystem.concat(nil, nil))
    end
  end

  describe "concat/2 when the second argument is nil" do
    test "returns the first argument" do
      language = %LanguageSystem{tag: "KOR ", required_feature: nil, features: []}

      assert LanguageSystem.concat(language, nil) === language
    end
  end

  describe "concat/2 when the first argument is nil" do
    test "returns the second argument" do
      language = %LanguageSystem{tag: "KOR ", required_feature: nil, features: []}

      assert LanguageSystem.concat(nil, language) === language
    end
  end

  describe "concat/2 when two language tags match" do
    test "concatenates two language systems, taking required feature from the first argument" do
      language_1 = %LanguageSystem{
        tag: "KOR ",
        required_feature: "Feature 1",
        features: ["Feature 2"]
      }

      language_2 = %LanguageSystem{
        tag: "KOR ",
        required_feature: "This will be discarded",
        features: ["Feature 3"]
      }

      expected = %LanguageSystem{
        tag: "KOR ",
        required_feature: "Feature 1",
        features: ["Feature 2", "Feature 3"]
      }

      assert LanguageSystem.concat(language_1, language_2) === expected
    end
  end

  describe "concat/2 when two language tags don't match" do
    test "returns the first argument" do
      language_1 = %LanguageSystem{tag: "KOR ", required_feature: nil, features: []}
      language_2 = %LanguageSystem{tag: "ENG ", required_feature: nil, features: []}

      assert LanguageSystem.concat(language_1, language_2) === language_1
    end
  end
end
