defmodule PixelFont.TableSource.OTFLayout.GlyphCoverageTest do
  use ExUnit.Case
  import Mox
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  describe "of/1" do
    test "creates GlyphCoverage struct from a nested enumerable" do
      glyph_ids = [0, 1, 2..4, [5, [6], 7..9]]
      coverage = GlyphCoverage.of(glyph_ids)

      assert %GlyphCoverage{glyphs: glyphs} = coverage
      assert Enum.all?(0..9, &(&1 in glyphs))
    end
  end

  describe "compile/2, when :internal option is set to false" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles coverage table format 1 when appropriate" do
      compiled_coverage =
        [10, 20, 30, 40, ~w(glyph10 glyph20 glyph30 glyph40)]
        |> GlyphCoverage.of()
        |> GlyphCoverage.compile()

      expected =
        [1, 8, 1010, 1020, 1030, 1040, 2010, 2020, 2030, 2040]
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_coverage === expected
    end

    test "compiles coverage table format 2 when appropriate" do
      compiled_coverage =
        [1, 2, 3, 4, ~w(glyph1 glyph2 glyph3 glyph4)]
        |> GlyphCoverage.of()
        |> GlyphCoverage.compile()

      expected =
        [2, 2, 1001, 1004, 0, 2001, 2004, 4]
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_coverage === expected
    end
  end

  describe "compile/2, when :internal option is set to true" do
    test "compiles coverage table without querying GlyphStorage" do
      compiled_coverage =
        [1..4]
        |> GlyphCoverage.of()
        |> GlyphCoverage.compile(internal: true)

      expected =
        [2, 1, 1, 4, 0]
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_coverage === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 8, fn
      code when is_integer(code) ->
        %Glyph{gid: 1000 + code}

      "glyph" <> digits ->
        {num, _} = Integer.parse(digits)

        %Glyph{gid: 2000 + num}
    end)

    :ok
  end
end
