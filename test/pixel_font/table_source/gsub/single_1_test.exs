defmodule PixelFont.TableSource.GSUB.Single1Test do
  use PixelFont.Case, async: true
  alias PixelFont.TableSource.GSUB.Single1
  alias PixelFont.TableSource.GSUB.Subtable
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  describe "compile/2" do
    test "compiles single substitution subtable format 1" do
      subtable = %Single1{
        gids: GlyphCoverage.of('ABCDE'),
        gid_diff: 32
      }

      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        to_wordstring([
          [1, 6, 32],
          # Coverage table
          [2, 1, ?A, ?E, 0]
        ])

      assert compiled_subtable === expected
    end
  end
end
