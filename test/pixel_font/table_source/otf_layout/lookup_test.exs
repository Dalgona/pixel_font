defmodule PixelFont.TableSource.OTFLayout.LookupTest do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.GSUB
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.OTFLayout.Lookup

  describe "compile/2" do
    test "compiles a Lookup table" do
      lookup = %Lookup{
        owner: GSUB,
        type: 1,
        name: "Test lookup",
        subtables: [%Single2{substitutions: [{?a, ?A}]}],
        features: %{}
      }

      compiled_lookup = Lookup.compile(lookup, [])

      expected =
        to_wordstring([
          [1, 0, 1, 8, []],
          # Lookup subtables
          [[2, 8, 1, ?A, [1, 1, ?a]]]
        ])

      assert compiled_lookup === expected
    end
  end
end
