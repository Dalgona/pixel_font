defmodule PixelFont.TableSource.GPOS.PairAdjustment2Test do
  use PixelFont.Case, async: true
  alias PixelFont.Font.Metrics
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GPOS.PairAdjustment2
  alias PixelFont.TableSource.GPOS.Subtable
  alias PixelFont.TableSource.GPOS.ValueRecord
  alias PixelFont.TableSource.OTFLayout.ClassDefinition

  setup_all do
    [metrics: %Metrics{units_per_em: 1024, pixels_per_em: 16}]
  end

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "compiles pair adjustment positioning subtable format 2", ctx do
      subtable = %PairAdjustment2{
        class_1: %ClassDefinition{
          assignments: %{1 => 'abc', 2 => 'def'}
        },
        class_2: %ClassDefinition{
          assignments: %{1 => 'pqr', 2 => 'xyz'}
        },
        value_format_1: [:x_advance],
        value_format_2: [:x_placement],
        records: %{
          {1, 1} => {%ValueRecord{x_advance: 1}, %ValueRecord{x_placement: 2}},
          {2, 0} => {%ValueRecord{x_advance: 3}, %ValueRecord{x_placement: 4}},
          {2, 2} => {%ValueRecord{x_advance: 5}, %ValueRecord{x_placement: 6}}
        }
      }

      compiled_subtable = Subtable.compile(subtable, [metrics: ctx.metrics])

      expected =
        to_wordstring([
          [2, 52, 0x04, 0x01, 62, 78, 3, 3],
          # Class records,
          [
            [[0, 0], [0, 0], [0, 0]],
            [[0, 0], [64, 128], [0, 0]],
            [[192, 256], [0, 0], [320, 384]]
          ],
          # Coverage table
          [2, 1, ?a, ?f, 0],
          # Class definitions 1
          [2, 2, [?a, ?c, 1], [?d, ?f, 2]],
          # Class definitions 2
          [2, 2, [?p, ?r, 1], [?x, ?z, 2]]
        ])

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 18, &%Glyph{gid: &1})

    :ok
  end
end
