defmodule PixelFont.TableSource.OTFLayout.ChainedSequenceContext2Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.{GPOS, GSUB}
  alias PixelFont.TableSource.OTFLayout.ClassDefinition
  alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext2

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "properly compiles chained sequence context subtable format 2" do
      subtable = %ChainedSequenceContext2{
        backtrack_classes: %ClassDefinition{assignments: %{1 => 'abc'}},
        input_classes: %ClassDefinition{assignments: %{1 => 'def'}},
        lookahead_classes: %ClassDefinition{assignments: %{1 => 'ghi'}},
        rulesets: %{
          1 => [
            %{
              backtrack: [1],
              input: [1],
              lookahead: [1],
              lookup_records: [{0, "Lookup 1"}, {1, "Lookup 2"}]
            }
          ]
        }
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}

      compiled_subtable =
        ChainedSequenceContext2.compile(subtable, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          [2, 16, 26, 36, 46, 2, [0, 56]],
          # Coverage table
          [2, 1, [?d, ?f, 0]],
          # Class definitions
          [
            [2, 1, [?a, ?c, 1]],
            [2, 1, [?d, ?f, 1]],
            [2, 1, [?g, ?i, 1]]
          ],
          # Ruleset tables
          [
            # Ruleset for input class 0 (empty)
            [],
            # Ruleset for input class 1
            [
              [1, [4]],
              [
                [1, [1], 2, [1], 1, [1], 2, [[0, 10], [1, 20]]]
              ]
            ]
          ]
        ])

      assert compiled_subtable === expected
    end
  end

  describe "protocols" do
    test "GPOS.Subtable protocol is implemented" do
      assert is_binary(GPOS.Subtable.compile(%ChainedSequenceContext2{}, []))
    end

    test "GSUB.Subtable protocol is implemented" do
      assert is_binary(GSUB.Subtable.compile(%ChainedSequenceContext2{}, []))
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 12, &%Glyph{gid: &1})

    :ok
  end
end
