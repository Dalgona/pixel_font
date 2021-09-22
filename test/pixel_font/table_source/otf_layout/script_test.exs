defmodule PixelFont.TableSource.OTFLayout.ScriptTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.OTFLayout.LanguageSystem
  alias PixelFont.TableSource.OTFLayout.Script

  describe "compile/2" do
    test "compiles an OpenType script table without default language system" do
      script = %Script{
        tag: "DFLT",
        default_language: nil,
        languages: [
          %LanguageSystem{tag: "KOR ", required_feature: nil, features: []}
        ]
      }

      compiled_script = Script.compile(script, [])

      expected =
        to_wordstring([
          [0, 1],
          [["KOR ", 10]],
          # Default language system table (empty)
          [],
          # Language system tables
          [
            [0, 0xFFFF, 0, []]
          ]
        ])

      assert compiled_script === expected
    end

    test "compiles an OpenType script table with a default language system" do
      script = %Script{
        tag: "DFLT",
        default_language: %LanguageSystem{tag: "dflt", required_feature: nil, features: []},
        languages: [
          %LanguageSystem{tag: "KOR ", required_feature: nil, features: []}
        ]
      }

      compiled_script = Script.compile(script, [])

      expected =
        to_wordstring([
          [10, 1],
          [["KOR ", 16]],
          # Default language system table
          [0, 0xFFFF, 0, []],
          # Language system tables
          [
            [0, 0xFFFF, 0, []]
          ]
        ])

      assert compiled_script === expected
    end
  end

  describe "concat/2 when two script tags match" do
    test "concatenates two scripts" do
      script_1 = %Script{
        tag: "hang",
        default_language: %LanguageSystem{
          tag: "dflt",
          required_feature: nil,
          features: ["Feature 1"]
        },
        languages: [
          %LanguageSystem{
            tag: "KOR ",
            required_feature: "Feature 2",
            features: ["Feature 3"]
          }
        ]
      }

      script_2 = %Script{
        tag: "hang",
        default_language: %LanguageSystem{
          tag: "dflt",
          required_feature: "Feature 4",
          features: ["Feature 5"]
        },
        languages: [
          %LanguageSystem{
            tag: "KOR ",
            required_feature: "This will be discarded",
            features: ["Feature 6"]
          }
        ]
      }

      expected = %Script{
        tag: "hang",
        default_language: %LanguageSystem{
          tag: "dflt",
          required_feature: "Feature 4",
          features: ["Feature 1", "Feature 5"]
        },
        languages: [
          %LanguageSystem{
            tag: "KOR ",
            required_feature: "Feature 2",
            features: ["Feature 3", "Feature 6"]
          }
        ]
      }

      assert Script.concat(script_1, script_2) === expected
    end
  end

  describe "concat/2 when two script tags don't match" do
    test "returns the first argument" do
      script_1 = %Script{tag: "hang", default_language: nil, languages: []}
      script_2 = %Script{tag: "latn", default_language: nil, languages: []}

      assert Script.concat(script_1, script_2) === script_1
    end
  end

  describe "sort_langs/1" do
    test "sorts language systems by language tag in ascending order" do
      script = %Script{
        tag: "latn",
        default_language: nil,
        languages: [
          %LanguageSystem{tag: "KOR ", required_feature: nil, features: []},
          %LanguageSystem{tag: "ENG ", required_feature: nil, features: []},
          %LanguageSystem{tag: "JAN ", required_feature: nil, features: []}
        ]
      }

      sorted_script = Script.sort_langs(script)

      assert Enum.map(sorted_script.languages, & &1.tag) === ["ENG ", "JAN ", "KOR "]
    end
  end
end
