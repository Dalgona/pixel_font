defmodule PixelFont.TableSource.OTFLayout.SequenceContext2Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.ClassDefinition
  alias PixelFont.TableSource.OTFLayout.SequenceContext2

  setup [:setup_mock, :verify_on_exit!]

  describe "compile/2" do
    test "properly compiles chained sequence context subtable format 2" do
      subtable = %SequenceContext2{
        input_classes: %ClassDefinition{
          assignments: %{1 => 'abc', 2 => 'def', 3 => 'ghi'}
        },
        rulesets: %{
          1 => [
            %{input: [2, 3], lookup_records: [{0, "Lookup 1"}, {2, "Lookup 2"}]}
          ]
        }
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}
      compiled_subtable = SequenceContext2.compile(subtable, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          [2, 16, 26, 4, [0, 48, 0, 0]],
          # Coverage table
          [2, 1, [?a, ?i, 0]],
          # Input class definition table
          [2, 3, [?a, ?c, 1], [?d, ?f, 2], [?g, ?i, 3]],
          # Class sequence ruleset tables
          [
            # Sequence ruleset for input class 0 (empty)
            [],
            # Sequence ruleset for input class 1
            [
              [1, 4],
              # Class sequence rule tables
              [
                [3, 2, [2, 3], [[0, 10], [2, 20]]]
              ]
            ],
            # Sequence ruleset for input class 2 (empty)
            [],
            # Sequence ruleset for input class 3 (empty)
            []
          ]
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
