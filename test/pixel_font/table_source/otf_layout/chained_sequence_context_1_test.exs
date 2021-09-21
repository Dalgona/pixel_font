defmodule PixelFont.TableSource.OTFLayout.ChainedSequenceContext1Test do
  use PixelFont.Case, async: true
  alias PixelFont.Glyph
  alias PixelFont.TableSource.{GPOS, GSUB}
  alias PixelFont.TableSource.OTFLayout.ChainedSequenceContext1

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    test "properly compiles chained sequence context subtable format 1" do
      subtable = %ChainedSequenceContext1{
        rulesets: %{
          ?a => [
            %{
              backtrack: 'zyx',
              input: 'bc',
              lookahead: 'def',
              lookup_records: [{0, "Lookup 1"}, {2, "Lookup 2"}]
            }
          ]
        }
      }

      lookup_indices = %{"Lookup 1" => 10, "Lookup 2" => 20}

      compiled_subtable =
        ChainedSequenceContext1.compile(subtable, lookup_indices: lookup_indices)

      expected =
        to_wordstring([
          [1, 8, 1, 14],
          # Coverage table
          [1, 1, ?a],
          # Ruleset tables
          [
            [
              [1, 4],
              # Rule tables
              [[3, 'zyx', 3, 'bc', 3, 'def', 2, 0, 10, 2, 20]]
            ]
          ]
        ])

      assert compiled_subtable === expected
    end
  end

  describe "protocols" do
    test "GPOS.Subtable protocol is implemented" do
      assert is_binary(GPOS.Subtable.compile(%ChainedSequenceContext1{}, []))
    end

    test "GSUB.Subtable protocol is implemented" do
      assert is_binary(GSUB.Subtable.compile(%ChainedSequenceContext1{}, []))
    end
  end

  defp setup_mock(_) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, 9, &%Glyph{gid: &1})

    :ok
  end
end
