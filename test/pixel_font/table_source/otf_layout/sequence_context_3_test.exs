defmodule PixelFont.TableSource.OTFLayout.SequenceContext3Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage
  alias PixelFont.TableSource.OTFLayout.SequenceContext3

  setup [:setup_mock, :verify_on_exit!]

  describe "compile/2" do
    test "properly compiles chained sequence context subtable format 3" do
      subtable = %SequenceContext3{
        input: [GlyphCoverage.of('abc'), GlyphCoverage.of('def'), GlyphCoverage.of('ghi')],
        lookup_records: [{0, "Lookup 1"}, {2, "Lookup 2"}]
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}
      compiled_subtable = SequenceContext3.compile(subtable, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          [3, 3, 2, [20, 30, 40], [[0, 10], [2, 20]]],
          # Coverage tables
          [
            [2, 1, [?a, ?c, 0]],
            [2, 1, [?d, ?f, 0]],
            [2, 1, [?g, ?i, 0]]
          ]
        ])

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 9, &%Glyph{gid: &1})

    :ok
  end
end
