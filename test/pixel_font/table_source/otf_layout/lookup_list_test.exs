defmodule PixelFont.TableSource.OTFLayout.LookupListTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.OTFLayout.Lookup
  alias PixelFont.TableSource.OTFLayout.LookupList

  describe "compile/2" do
    test "compiles a OpenType lookup list table" do
      lookup_list = %LookupList{
        lookups: [
          %Lookup{
            owner: GSUB,
            type: 1,
            name: "Lookup 1",
            features: %{},
            subtables: [%Single2{substitutions: [{?A, ?a}]}]
          },
          %Lookup{
            owner: GSUB,
            type: 6,
            name: "Lookup 2",
            features: %{},
            subtables: []
          }
        ]
      }

      compiled_list = LookupList.compile(lookup_list, [])

      expected =
        to_wordstring([
          [2, [6, 28]],
          [
            # Lookup tables
            [1, 0, 1, [8], [], [[2, 8, 1, [?a], [1, 1, ?A]]]],
            [6, 0, 0, [], [], []]
          ]
        ])

      assert compiled_list === expected
    end
  end

  describe "concat/2" do
    test "concatenates two lookup lists" do
      lookup_1 = %Lookup{owner: GSUB, type: 1, name: "Lookup 1", features: %{}, subtables: []}
      lookup_2 = %Lookup{owner: GSUB, type: 6, name: "Lookup 2", features: %{}, subtables: []}
      lookup_list_1 = %LookupList{lookups: [lookup_1]}
      lookup_list_2 = %LookupList{lookups: [lookup_2]}
      concatenated = LookupList.concat(lookup_list_1, lookup_list_2)

      assert concatenated.lookups === [lookup_1, lookup_2]
    end
  end
end
