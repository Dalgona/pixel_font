defmodule PixelFont.TableSource.GSUB.Alternate1Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB.Alternate1
  alias PixelFont.TableSource.GSUB.Subtable

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles alternate substitution subtable format 1" do
      subtable = %Alternate1{alternatives: %{?a => ~c"12", ?b => ~c"345"}}
      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        to_wordstring([
          [1, 10, 2, 18, 24],
          # Coverage table
          [1, 2, ~c"ab"],
          # Alternate set tables
          [[2, ~c"12"], [3, ~c"345"]]
        ])

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 7, &%Glyph{gid: &1})

    :ok
  end
end
