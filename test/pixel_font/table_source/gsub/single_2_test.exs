defmodule PixelFont.TableSource.GSUB.Single2Test do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.GSUB.Single2
  alias PixelFont.TableSource.GSUB.Subtable

  describe "compile/2" do
    test "compiles single substitution subtable format 2" do
      subtable = %Single2{
        substitutions: [{?A, ?a}, {?B, ?b}, {?C, ?c}, {?D, ?d}, {?E, ?e}]
      }

      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        to_wordstring([
          [2, 16, 5, 'abcde'],
          # Coverage table
          [2, 1, ?A, ?E, 0]
        ])

      assert compiled_subtable === expected
    end
  end
end
