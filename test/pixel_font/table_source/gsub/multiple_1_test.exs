defmodule PixelFont.TableSource.GSUB.Multiple1Test do
  use ExUnit.Case, async: true
  import Mox
  alias PixelFont.Glyph
  alias PixelFont.TableSource.GSUB.Multiple1
  alias PixelFont.TableSource.GSUB.Subtable

  describe "compile/2" do
    setup [:setup_mock, :verify_on_exit!]

    @tag glyph_storage_get_count: 6
    test "compiles multiple substitution subtable format 1" do
      subtable = %Multiple1{substitutions: [{?A, 'aa'}, {?B, 'bb'}]}
      compiled_subtable = Subtable.compile(subtable, [])

      expected =
        [
          [1, 10, 2, 18, 24],
          # Coverage table
          [1, 2, 'AB'],
          # Sequence tables
          [[2, 'aa'], [2, 'bb']]
        ]
        |> List.flatten()
        |> Enum.map(&<<&1::16>>)
        |> IO.iodata_to_binary()

      assert compiled_subtable === expected
    end

    @tag glyph_storage_get_count: 1
    test "raises an error when substitution sequence is empty" do
      subtable = %Multiple1{substitutions: [{?A, ''}]}

      assert_raise ArgumentError, fn -> Subtable.compile(subtable, []) end
    end
  end

  defp setup_mock(context) do
    PixelFont.GlyphStorage.Mock
    |> expect(:get, context[:glyph_storage_get_count], &%Glyph{gid: &1})

    :ok
  end
end
