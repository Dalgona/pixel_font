defmodule PixelFont.TableSource.GSUB.Ligature1Test do
  use ExUnit.Case, async: true
  import Mox
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB.Ligature1
  alias PixelFont.TableSource.GSUB.Subtable

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles ligature substitution subtable format 1" do
      subtable = %Ligature1{
        substitutions: [{'abc', ?X}, {'ab', ?Y}, {'def', ?Z}]
      }

      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        [
          [1, 10, 2, 18, 38],
          # Coverage table
          [1, 2, ?a, ?d],
          # Ligature set tables
          [
            [2, 6, 14, [?X, 3, 'bc'], [?Y, 2, 'b']],
            [1, 4, [?Z, 3, 'ef']]
          ]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 11, &%Glyph{gid: &1})

    :ok
  end
end
