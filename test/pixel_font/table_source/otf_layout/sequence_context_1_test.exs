defmodule PixelFont.TableSource.OTFLayout.SequenceContext1Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.OTFLayout.SequenceContext1

  setup [:setup_mock, :verify_on_exit!]

  describe "compile/2" do
    test "properly compiles chained sequence context subtable format 1" do
      subtable = %SequenceContext1{
        rulesets: %{
          ?a => [
            %{input: 'bc', lookup_records: [{0, "Lookup 1"}, {2, "Lookup 2"}]}
          ]
        }
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}
      compiled_subtable = SequenceContext1.compile(subtable, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          [1, 8, 1, [14]],
          # Coverage table
          [1, 1, ?a],
          # Sequence ruleset tables
          [
            [
              [1, 4],
              # Sequence rule tables
              [
                [3, 2, 'bc', [[0, 10], [2, 20]]]
              ]
            ]
          ]
        ])

      assert compiled_subtable === expected
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 3, &%Glyph{gid: &1})

    :ok
  end
end
