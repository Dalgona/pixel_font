defmodule PixelFont.TableSource.GPOS.SingleAdjustment1Test do
  use ExUnit.Case
  import Mox
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GPOS.SingleAdjustment1
  alias PixelFont.TableSource.GPOS.Subtable
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles single adjustment positioning subtable format 1" do
      subtable = %SingleAdjustment1{
        glyphs: GlyphCoverage.of('abcde'),
        value_format: [:x_placement],
        value: %ValueRecord{x_placement: 10}
      }

      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        [
          [1, 8, 1, 10],
          # Coverage table
          [2, 1, ?a, ?e, 0]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 5, &%Glyph{gid: &1})

    :ok
  end
end
