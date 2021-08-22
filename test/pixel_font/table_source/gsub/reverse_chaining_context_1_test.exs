defmodule PixelFont.TableSource.GSUB.ReverseChainingContext1Test do
  use ExUnit.Case, async: true
  import Mox
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB.ReverseChainingContext1
  alias PixelFont.TableSource.GSUB.Subtable
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles reverse chaining contextual single substitution subtable format 1" do
      subtable = %ReverseChainingContext1{
        backtrack: [GlyphCoverage.of('abc'), GlyphCoverage.of('def')],
        lookahead: [GlyphCoverage.of('uvw'), GlyphCoverage.of('xyz')],
        substitutions: [{?X, ?0}, {?Y, ?1}]
      }

      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        [
          [1, 22, 2, 30, 40, 2, 50, 60, 2, '01'],
          # Coverage table
          [1, 2, 'XY'],
          # Backtrack coverage tables
          [[2, 1, ?a, ?c, 0], [2, 1, ?d, ?f, 0]],
          # Lookahead coverage tables
          [[2, 1, ?u, ?w, 0], [2, 1, ?x, ?z, 0]]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 16, &%Glyph{gid: &1})

    :ok
  end
end
