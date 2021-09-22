defmodule PixelFont.TableSource.OTFLayout.ScriptListTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.OTFLayout.LanguageSystem
  alias PixelFont.TableSource.OTFLayout.Script
  alias PixelFont.TableSource.OTFLayout.ScriptList

  describe "compile/2" do
    test "compiles an OpenType script list table" do
      script_list = %ScriptList{
        scripts: [
          %Script{
            tag: "DFLT",
            default_language: %LanguageSystem{tag: "dflt", required_feature: nil, features: []},
            languages: []
          },
          %Script{
            tag: "latn",
            default_language: %LanguageSystem{tag: "dflt", required_feature: nil, features: []},
            languages: [
              %LanguageSystem{tag: "ENG ", required_feature: nil, features: []}
            ]
          }
        ]
      }

      compiled_list = ScriptList.compile(script_list, [])

      expected =
        to_wordstring([
          [2, [["DFLT", 14], ["latn", 24]]],
          [
            # Script tables
            [
              [4, 0, []],
              [0, 0xFFFF, 0, []],
              []
            ],
            [
              [10, 1, [["ENG ", 16]]],
              [0, 0xFFFF, 0, []],
              [
                [0, 0xFFFF, 0, []]
              ]
            ]
          ]
        ])

      assert compiled_list === expected
    end
  end

  describe "concat/2" do
    script_1 = %Script{
      tag: "DFLT",
      default_language: nil,
      languages: [%LanguageSystem{tag: "ENG ", required_feature: nil, features: []}]
    }

    script_2 = %Script{
      tag: "DFLT",
      default_language: %LanguageSystem{tag: "dflt", required_feature: nil, features: []},
      languages: []
    }

    script_3 = %Script{tag: "latn", default_language: nil, languages: []}
    script_list_1 = %ScriptList{scripts: [script_1]}
    script_list_2 = %ScriptList{scripts: [script_2, script_3]}
    concatenated = ScriptList.concat(script_list_1, script_list_2)

    expected_scripts = [
      %Script{
        tag: "DFLT",
        default_language: %LanguageSystem{tag: "dflt", required_feature: nil, features: []},
        languages: [%LanguageSystem{tag: "ENG ", required_feature: nil, features: []}]
      },
      script_3
    ]

    assert concatenated.scripts === expected_scripts
  end

  describe "sort/1" do
    test "sorts a script list table and its languages by script/language tag" do
      script_list = %ScriptList{
        scripts: [
          %Script{
            tag: "latn",
            default_language: nil,
            languages: [
              %LanguageSystem{tag: "ENG ", required_feature: nil, features: []},
              %LanguageSystem{tag: "DEU ", required_feature: nil, features: []}
            ]
          },
          %Script{
            tag: "hang",
            default_language: nil,
            languages: []
          }
        ]
      }

      sorted_list = ScriptList.sort(script_list)

      expected = %ScriptList{
        scripts: [
          %Script{
            tag: "hang",
            default_language: nil,
            languages: []
          },
          %Script{
            tag: "latn",
            default_language: nil,
            languages: [
              %LanguageSystem{tag: "DEU ", required_feature: nil, features: []},
              %LanguageSystem{tag: "ENG ", required_feature: nil, features: []}
            ]
          }
        ]
      }

      assert sorted_list === expected
    end
  end
end
