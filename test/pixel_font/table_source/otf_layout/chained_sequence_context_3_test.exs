defmodule PixelFont.TableSource.OTFLayout.ChainedSequenceContext3Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext3
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "properly compiles chained sequence context subtable format 3" do
      subtable = %ChainedSequenceContext3{
        backtrack: [GlyphCoverage.of('abc')],
        input: [GlyphCoverage.of('def'), GlyphCoverage.of('ghi')],
        lookahead: [GlyphCoverage.of('jkl')],
        lookup_records: [{0, "Lookup 1"}, {1, "Lookup 2"}]
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}

      compiled_subtable =
        ChainedSequenceContext3.compile(subtable, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          [3, 1, 26, 2, 36, 46, 1, 56, 2],
          # Lookup records
          [[0, 10], [1, 20]],
          # Backtrack coverage tables
          [[2, 1, ?a, ?c, 0]],
          # Input coverage tables
          [[2, 1, ?d, ?f, 0], [2, 1, ?g, ?i, 0]],
          # Lookahead coverage tables
          [[2, 1, ?j, ?l, 0]]
        ])

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 12, &%Glyph{gid: &1})

    :ok
  end
end
