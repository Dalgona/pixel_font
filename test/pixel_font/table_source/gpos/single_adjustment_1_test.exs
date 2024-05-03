defmodule PixelFont.TableSource.GPOS.SingleAdjustment1Test do
  use PixelFont.Case, async: true
  alias PixelFont.Font.Metrics
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GPOS.SingleAdjustment1
  alias PixelFont.TableSource.GPOS.Subtable
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.GlyphCoverage

  setup_all do
    [metrics: %Metrics{units_per_em: 1024, pixels_per_em: 16}]
  end

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles single adjustment positioning subtable format 1", ctx do
      subtable = %SingleAdjustment1{
        glyphs: GlyphCoverage.of('abcde'),
        value_format: [:x_placement],
        value: %ValueRecord{x_placement: 10}
      }

      compiled_subtable = Subtable.compile(subtable, [metrics: ctx.metrics])

      expected =
        to_wordstring([
          [1, 8, 1, 640],
          # Coverage table
          [2, 1, ?a, ?e, 0]
        ])

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 5, &%Glyph{gid: &1})

    :ok
  end
end
